// Runs in Luakit's eval_js world. Inaccessible frames fail closed.
(function (resetEdited) {
    "use strict";
    const key = "__luakitTmpAutoUnloadV1";
    let state = window[key];
    if (!state || state.document !== document) {
        state = window[key] = {
            document, edited: false, submitted: false, frameGap: false,
            late: document.readyState !== "loading", lateForms: false,
            documents: new WeakSet(), roots: new WeakSet(),
            baseline: new WeakMap(), defaults: new WeakMap()
        };
    }
    const reasons = new Set();
    const controls = [];
    const editables = [];
    const textTypes = new Set(["text", "search", "url", "tel", "email", "password",
        "number", "date", "datetime-local", "month", "time", "week"]);
    const editableEvent = event => event.composedPath().some(node =>
        node && node.nodeType === 1 &&
        (node.matches("input,textarea,select") || node.isContentEditable));
    function value(element) {
        if (element.matches("input[type=checkbox],input[type=radio]"))
            return element.checked;
        if (element.matches("select"))
            return Array.from(element.options, option => option.selected).join(",");
        return element.value;
    }
    function defaultValue(element) {
        if (element.matches("input[type=checkbox],input[type=radio]"))
            return element.defaultChecked;
        if (element.matches("select")) {
            // For a single select with no explicit default, the first option
            // is normally selected. Compare option defaults conservatively.
            const explicit = Array.from(element.options).some(o => o.defaultSelected);
            return Array.from(element.options, (o, i) =>
                o.defaultSelected || (!element.multiple && !explicit && i === 0)).join(",");
        }
        return element.defaultValue;
    }
    function listen(root) {
        if (state.roots.has(root)) return;
        state.roots.add(root);
        for (const name of ["beforeinput", "input", "change"]) {
            root.addEventListener(name, event => {
                if (editableEvent(event)) state.edited = true;
            }, true);
        }
        root.addEventListener("submit", () => { state.submitted = true; }, true);
        // A frame can be inserted, edited and removed between periodic probes.
        // Native Luakit APIs cannot install a document-start observer in every
        // frame, so remember this uncertainty even after the frame disappears.
        new MutationObserver(records => {
            for (const record of records) for (const node of record.addedNodes) {
                if (node.nodeType === 1 && (node.matches("iframe,frame") ||
                    node.querySelector("iframe,frame"))) state.frameGap = true;
            }
        }).observe(root, { childList: true, subtree: true });
    }
    function scanRoot(root) {
        listen(root);
        for (const element of root.querySelectorAll("*")) {
            if (element.matches("input,textarea,select")) {
                if (element.matches("input[type=file]") && element.files.length)
                    reasons.add("selected files / possible upload");
                // Hidden/button controls often change for internal bookkeeping.
                if (!element.matches("input[type=hidden],input[type=submit],input[type=button],input[type=reset],input[type=image]"))
                    controls.push(element);
            }
            if (element.isContentEditable &&
                (!element.parentElement || !element.parentElement.isContentEditable))
                editables.push(element);
            if (element.matches("audio,video")) {
                if (!element.paused && !element.ended) reasons.add("playing media");
                if (element.paused && !element.ended && Number.isFinite(element.currentTime) && element.currentTime > 0)
                    reasons.add("paused media with playback progress");
                if (element.srcObject && typeof element.srcObject.getTracks === "function" &&
                    element.srcObject.getTracks().some(track => track.readyState === "live"))
                    reasons.add("live media stream");
            }
            if (element.shadowRoot) scanRoot(element.shadowRoot);
            if (element.matches("iframe,frame")) {
                state.frameGap = true;
                try {
                    const child = element.contentWindow;
                    if (!child || !child.document) reasons.add("uninspectable frame");
                    else scanDocument(child.document);
                } catch (_) {
                    reasons.add("uninspectable frame");
                }
            }
        }
    }
    function scanDocument(doc) {
        if (doc.readyState !== "complete") reasons.add("document / frame loading");
        // An onbeforeunload property is only an extra warning, never proof of
        // safety: addEventListener handlers cannot be enumerated reliably.
        if (doc.defaultView.onbeforeunload) reasons.add("page unload warning");
        if (!state.documents.has(doc)) {
            state.documents.add(doc);
            doc.addEventListener("pagehide", () => { state.submitted = true; }, true);
        }
        scanRoot(doc);
    }
    scanDocument(document);
    // Inspect current state independently of events and acknowledged edits.
    for (const element of controls) {
        if (!state.defaults.has(element)) state.defaults.set(element, defaultValue(element));
        if (element.matches("input[type=checkbox],input[type=radio],select")) {
            if (value(element) !== state.defaults.get(element)) reasons.add("changed form selection");
        } else if ((element.localName === "textarea" || textTypes.has(element.type)) &&
            value(element) !== state.defaults.get(element)) {
            reasons.add("changed form value");
        }
    }
    if (editables.some(element => element.innerHTML !== "")) reasons.add("editable document contents");
    if (state.late && (controls.length || editables.length || document.querySelector("form")))
        state.lateForms = true;
    if (resetEdited) {
        state.edited = false;
        state.late = state.lateForms = false;
        for (const element of controls) state.baseline.set(element, value(element));
        for (const element of editables) state.baseline.set(element, element.innerHTML);
    } else {
        for (const element of controls) {
            const baseline = state.baseline.has(element)
                ? state.baseline.get(element) : state.defaults.get(element);
            if (value(element) !== baseline) state.edited = true;
        }
        for (const element of editables) {
            // Never assume existing editor contents were saved before loading
            // this experiment (or that custom editor defaults are meaningful).
            const baseline = state.baseline.has(element) ? state.baseline.get(element) : "";
            if (element.innerHTML !== baseline) state.edited = true;
        }
    }
    if (state.frameGap) reasons.add("frame observation cannot cover earlier interactions");
    if (state.lateForms) reasons.add("form observation started late; acknowledge saved contents to reset");
    if (state.edited) reasons.add("edited form / document");
    if (state.submitted) reasons.add("submitted form / pending operation");
    return { edited: state.edited, reason: Array.from(reasons).join("; ") };
})(AUTO_UNLOAD_RESET_EDITED)
