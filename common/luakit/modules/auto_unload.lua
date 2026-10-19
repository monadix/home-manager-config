-- Load from userconf.lua before session restoration. Overrides are ordinary
-- session/undoclose metadata; there is no separate persistence store.
local modes = require("modes")
local window = require("window")
modes.add_binds("normal", {
    { ",k", "Toggle keep-loaded protection.", function (w) w:match_cmd("keep-loaded") end },
    { ",u", "Toggle explicit unload eligibility (bypasses safeguards).", function (w) w:match_cmd("allow-unload") end },
    { ",s", "Show automatic-unload protection status.", function (w) w:match_cmd("unload-status") end },
    { ",E", "Acknowledge saved/disposable edits.", function (w) w:match_cmd("unload-reset-edited") end },
})
for _, w in pairs(window.bywidget) do
    if w.mode and w.mode.name == "normal" then w:update_binds("normal") end
end
local webview = require("webview")
local tab = require("lousy.widget.tab")
local escape = require("lousy.util").escape
local session = require("session")
local undoclose = require("undoclose")
assert(type(undoclose.replace_view) == "function", "auto_unload requires the HM Luakit metadata patch")
local probe_file = assert(io.open(luakit.config_dir .. "/modules/auto_unload_probe.js", "r"))
local probe_js = probe_file:read("*a")
probe_file:close()

local M = { timeout = 30 * 60 }
local states = setmetatable({}, { __mode = "k" })
local labels = setmetatable({}, { __mode = "kv" })
local GREEN, YELLOW, PURPLE, GRAY = "#a3be8c", "#d6bb75", "#a99bbd", "#858891"
local probe, wake, resolving_notebook

local function link_label(tl, view)
    labels[tl] = view
    tl.widget:add_signal("destroy", function () labels[tl] = nil end)
end

local function now() return luakit.time() end
local function refresh(view)
    for tl, v in pairs(labels) do
        if v == view then tl.index = tl.index end
    end
end

local function owner(view)
    local w = webview.window(view)
    if w and w.tabs and w.tabs:indexof(view) then return w end
end

local function visible(view)
    local w = owner(view)
    return not w or w.tabs[w.tabs:current()] == view
end

local function downloads_running()
    local downloads = package.loaded.downloads
    if not downloads then return false end
    for d in pairs(downloads.get_all()) do
        if d.status == "created" or d.status == "started" then return true end
    end
    return false
end

local function native_reason(view, s)
    if s.override == "keep" then return "explicit keep loaded" end
    if webview.has_load_block(view) then return "page load blocked / lazy restored" end
    if s.override == "unload" then return end
    if s.capture then return "media permission requested (possible call / capture)" end
    if s.capture_unknown then return "pre-existing tab: capture state unknown; reopen tab to monitor" end
    if s.edited then return "edited form / document" end
    if view.is_loading then return "page loading" end
    if view.is_playing_audio then return "playing audio" end
    if not (view.uri or ""):match("^https?://") and not (view.uri or ""):match("^file://") then
        return "internal / unsupported page"
    end
    -- Downloads are managed globally; without a reliable per-tab association,
    -- conservatively leave all tabs loaded until transfers finish.
    if downloads_running() then return "download running" end
end

local function protect(view, s, reason)
    s.reason = reason
    refresh(view)
end

local function install(view, existing)
    if states[view] then return states[view] end
    local s = {
        last_active = now(), generation = 0,
        reason = "safety check pending", capture_unknown = existing or false,
    }
    states[view] = s
    view:add_signal("destroy", function () states[view] = nil end)
    view:add_signal("load-status", function (_, status)
        if status == "provisional" then
            s.generation = s.generation + 1
            s.pending = nil
            s.reason = "page loading"
        elseif status == "committed" then
            s.generation = s.generation + 1
            s.pending = nil
            s.edited, s.capture, s.observed = false, false, false
            probe(view, false)
        elseif status == "finished" then
            -- WebKit may still report is_loading inside the signal callback.
            luakit.idle_add(function ()
                if states[view] == s then probe(view, false) end
            end)
        end
        refresh(view)
    end)
    -- Cover user interaction during the asynchronous first observer install.
    -- Only this short unobserved interval uses these conservative native guards.
    view:add_signal("key-press", function ()
        if not s.observed and not s.sleeping then
            s.edited = true
            protect(view, s, "interaction before edit observation")
        end
    end)
    view:add_signal("button-press", function (_, _, _, context)
        if not s.observed and context and context.editable and not s.sleeping then
            s.edited = true
            protect(view, s, "interaction before edit observation")
        end
    end)
    view:add_signal("permission-request", function (_, kind)
        if kind == "user-media" then
            -- Do not grant/deny permission here. Protect even if another
            -- handler denies it: there is no capture-ended API in this build.
            s.capture = true
            protect(view, s, native_reason(view, s))
        end
    end)
    view:add_signal("property::is-playing-audio", function ()
        if view.is_playing_audio then protect(view, s, "playing audio") end
    end)
    view:add_signal("switched-page", function ()
        s.last_active = now()
        wake(view)
        probe(view, false)
    end)
    return s
end

wake = function (view)
    local s = states[view]
    if not s or not s.sleeping then return end
    s.sleeping = nil
    s.reason = "restoring page"
    s.last_active = now()
    webview.modify_load_block(view, "tmp-auto-unload", false)
    refresh(view)
end

local function unload(view, s)
    local w = owner(view)
    if not w or visible(view) or s.override == "keep" or s.sleeping then return end
    if native_reason(view, s) or now() - s.last_active < M.timeout then return end
    local saved = { uri = view.uri, session_state = view.session_state,
                    title = view.title, private = view.private }
    if not saved.session_state or saved.session_state == "" then
        protect(view, s, "cannot save tab history")
        return
    end
    local index = w.tabs:indexof(view)
    local replacement = webview.new({ private = saved.private })
    local rs = states[replacement]
    undoclose.replace_view(view, replacement)
    rs.sleeping, rs.reason, rs.override = saved, nil, s.override
    rs.last_active = s.last_active
    webview.modify_load_block(replacement, "tmp-auto-unload", true)
    -- webview's blocked URI/session_state getters expose this saved state to
    -- the session saver without loading the page.
    webview.set_location(replacement, saved)
    w.tabs:insert(index, replacement)
    -- Like window.new_tab, bootstrap the blank view's WebProcess so adblock's
    -- initialization blocker can complete. The saved page remains load-blocked.
    replacement:reload()
    -- Do not use close_tab: automatic unloading must not add undo-close items.
    w:detach_tab(view, false)
    view:destroy()
    refresh(replacement)
end

probe = function (view, may_unload, reset_edited)
    local s = states[view]
    if not s or s.sleeping then return end
    if may_unload and s.override == "unload" then unload(view, s); return end
    if s.pending then return end
    local reason = native_reason(view, s)
    if reason then protect(view, s, reason) end
    -- Still install edit listeners when a tab is pinned or playing audio.
    -- Otherwise an edit made and cleared during protection could be missed.
    if webview.has_load_block(view) or
        not (view.uri or ""):match("^(https?)://") and not (view.uri or ""):match("^file://") then
        return
    end
    local request = { generation = s.generation, started = now() }
    s.pending = request
    local script = probe_js:gsub("AUTO_UNLOAD_RESET_EDITED", reset_edited and "true" or "false")
    local ok = pcall(function ()
        view:eval_js(script, { source = "modules/auto_unload_probe.js", callback = function (result, err)
            if states[view] ~= s or s.pending ~= request or s.generation ~= request.generation then return end
            s.pending = nil
            if err or type(result) ~= "table" or type(result.reason) ~= "string"
                or type(result.edited) ~= "boolean" then
                protect(view, s, "safety check failed")
                return
            end
            s.observed = true
            if reset_edited then s.edited = result.edited
            else s.edited = s.edited or result.edited end
            local blocked = native_reason(view, s) or
                (s.override ~= "unload" and result.reason ~= "" and result.reason or nil)
            protect(view, s, blocked)
            if may_unload and not blocked and not visible(view) then unload(view, s) end
        end })
    end)
    if not ok and s.pending == request then
        s.pending = nil
        protect(view, s, "safety check failed")
    end
end

-- Color the title text, retaining the normal current-tab background, security
-- index colors, and hover behavior. Sleeping gray overrides policy colors.
local original_title = tab.label_subs.title
tab.label_subs.title = function (tl)
    local view = labels[tl]
    if not view and resolving_notebook then
        -- Initial label refresh runs with a known notebook. Avoid rebuilding
        -- widgets: favicon handlers would retain destroyed icon widgets.
        view = resolving_notebook[tonumber(tl.index)]
        link_label(tl, view)
    end
    local s = view and states[view]
    if not s then return original_title(tl) end
    local title = s.sleeping and ("[z] " .. escape(s.sleeping.title or s.sleeping.uri))
                  or original_title(tl)
    local color = s.sleeping and GRAY or s.override == "keep" and YELLOW or
        s.override == "unload" and PURPLE or s.reason and GREEN
    return color and ('<span foreground="' .. color .. '">' .. title .. '</span>') or title
end
tab.add_signal("build", link_label)
-- Attach before webview init handlers, especially permission handlers that
-- return a decision and stop propagation to later listeners.
widget.add_signal("create", function (view)
    if view.type == "webview" then install(view, false) end
end)
webview.add_signal("init", function (view) install(view, false) end)

local function install_window(w, existing)
    local previous = w.tabs[w.tabs:current()]
    for _, view in ipairs(w.tabs.children) do install(view, existing) end
    w.tabs:add_signal("switch-page", function (_, view)
        local old = previous
        previous = view
        if old and states[old] then
            states[old].last_active = now()
            probe(old, false)
        end
        if states[view] then
            states[view].last_active = now()
            wake(view)
            probe(view, false)
        end
    end)
    if existing then
        for index, view in ipairs(w.tabs.children) do
            local s = states[view]
            protect(view, s, native_reason(view, s) or s.reason)
            -- Refresh indices/labels without changing the actual tab order.
            resolving_notebook = w.tabs
            w.tabs:emit_signal("page-reordered", view, index)
            resolving_notebook = nil
        end
    end
end
window.add_signal("init", function (w) install_window(w, false) end)
for _, w in pairs(window.bywidget) do install_window(w, true) end

local function restore_metadata(view, item)
    local s = states[view]
    if not s then return end
    local value = item.auto_unload_override
    s.override = (value == "keep" or value == "unload") and value or nil
    refresh(view)
end

session.add_signal("save", function (saved)
    for w, win in pairs(saved) do
        for i, view in ipairs(w.tabs.children) do
            if not view.private then
                win.open[i].auto_unload_override = states[view].override
            end
        end
    end
end)
session.add_signal("restore", function (saved)
    for w, win in pairs(saved) do
        for i, view in ipairs(w.tabs.children) do restore_metadata(view, win.open[i]) end
    end
end)
undoclose.add_signal("save-item", function (view, item)
    item.auto_unload_override = states[view] and states[view].override or nil
end)
undoclose.add_signal("restore-item", restore_metadata)

-- Undolist's background/new-window actions pass the saved record directly.
local original_set_location = webview.set_location
webview.set_location = function (view, arg)
    if type(arg) == "table" and arg.self_uid ~= nil then
        restore_metadata(view, arg)
        -- A blocked location is replayed later; consume metadata only once.
        arg = { uri = arg.uri, session_state = arg.session_state }
    end
    return original_set_location(view, arg)
end

-- Closing a sleeping background tab must also work before adblock or other
-- initialization blockers finish. Restore history directly, bypassing load
-- blocks only for this immediate destruction, so undoclose can read it.
local original_close = window.methods.close_tab
window.methods.close_tab = function (w, view, ...)
    local v = view or w.view
    local s = states[v]
    if s and s.sleeping then v.session_state = s.sleeping.session_state end
    return original_close(w, view, ...)
end

local function set_override(w, value)
    local view, s = w.view, states[w.view]
    if not s then return end
    s.override, s.last_probe, s.last_active = value, nil, now()
    if value == "keep" then wake(view) end
    protect(view, s, native_reason(view, s) or "safety check pending")
    probe(view, false)
    if not view.private then
        local ok, err = pcall(session.save)
        if not ok then w:error("Override active, but session save failed: " .. tostring(err)); return end
    end
    local label = value == "keep" and "Keep loaded: on (yellow)" or
        value == "unload" and "Unload eligible: on (gray-purple); safeguards bypassed" or
        "Override: default; automatic safeguards restored"
    w:notify(label .. (view.private and " (private tab: memory only)" or " (saved in session)"))
end

modes.add_cmds({
    { ":keep-loaded", "Toggle keep-loaded protection.", function (w)
        local s = states[w.view]
        if s then set_override(w, s.override ~= "keep" and "keep" or nil) end
    end },
    { ":allow-unload", "Toggle unload eligibility, bypassing safeguards.", function (w)
        local s = states[w.view]
        if s then set_override(w, s.override ~= "unload" and "unload" or nil) end
    end },
    { ":unload-reset-edited", "Acknowledge saved/disposable edits in this tab.", function (w)
        local s = states[w.view]
        if not s or s.pending then w:notify("Safety check pending; try again shortly") return end
        probe(w.view, false, true)
        w:notify("Rechecking edits against current contents; other protections remain")
    end },
    { ":unload-status", "Explain why this tab is kept loaded.", function (w)
        local s = states[w.view]
        if not s then return end
        local reason = native_reason(w.view, s) or
            (s.override == "unload" and "explicit eligibility; safeguards bypassed") or
            s.reason or "no detected protected state"
        w:notify("Override: " .. (s.override or "default") .. "; " .. reason ..
            "; visible tabs are never unloaded; background timeout: 30 minutes")
    end },
})

local poll = timer { interval = 15000 }
poll:add_signal("timeout", function ()
    local candidates = {}
    for view, s in pairs(states) do candidates[#candidates + 1] = { view, s } end
    for _, pair in ipairs(candidates) do
        local view, s = pair[1], pair[2]
        if states[view] == s then
            if s.pending and now() - s.pending.started >= 10 then
                s.pending = nil
                protect(view, s, "safety check timed out")
            end
            if not s.sleeping then
                if visible(view) then
                    s.last_active = now()
                    probe(view, false)
                elseif now() - s.last_active >= M.timeout then
                    -- Retry background checks at most once per minute; do not
                    -- wake every inactive renderer on every timer tick.
                    if not s.last_probe or now() - s.last_probe >= 60 then
                        s.last_probe = now()
                        probe(view, true)
                    end
                end
            end
        end
    end
end)
poll:start()
M.timer = poll
return M
