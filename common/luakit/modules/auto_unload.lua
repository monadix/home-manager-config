-- Load from userconf.lua before session restoration. Overrides are ordinary
-- session/undoclose metadata; there is no separate persistence store.
local modes = require("modes")
local window = require("window")
local webview = require("webview")
local tab = require("lousy.widget.tab")
local escape = require("lousy.util").escape
local session = require("session")
local undoclose = require("undoclose")
local settings = require("settings")
assert(type(undoclose.replace_view) == "function", "auto_unload requires the HM Luakit metadata patch")

local function validator (min)
    return function (v) local n = tonumber(v); return n ~= nil and n >= min end
end

settings.register_settings({
    ["auto_unload.idle_timeout"] = {
        type = "number", default = 10, validator = validator(0),
        desc = "Minutes a background tab must stay inactive before it may be unloaded.",
    },
    ["auto_unload.max_loaded"] = {
        type = "number", default = 12, validator = validator(0),
        desc = "Unload the least recently used background tab above this many loaded tabs; 0 disables.",
    },
    ["auto_unload.memory_low_mb"] = {
        type = "number", default = 1536, validator = validator(0),
        desc = "Available memory in MiB below which one background tab is unloaded per check.",
    },
    ["auto_unload.memory_high_mb"] = {
        type = "number", default = 2560, validator = validator(0),
        desc = "Available memory in MiB at which memory-pressure unloading stops.",
    },
    ["auto_unload.wake_grace"] = {
        type = "number", default = 5, validator = validator(0),
        desc = "Minutes a tab is exempt from count and memory-pressure unloading after loading.",
    },
})

local function setting (name) return settings.get_setting("auto_unload." .. name) end

modes.add_binds("normal", {
    { ",k", "Toggle keep-loaded protection.", function (w) w:match_cmd("keep-loaded") end },
    { ",u", "Toggle explicit unload eligibility (bypasses safeguards).", function (w) w:match_cmd("allow-unload") end },
    { ",s", "Show automatic-unload protection status.", function (w) w:match_cmd("unload-status") end },
})
for _, w in pairs(window.bywidget) do
    if w.mode and w.mode.name == "normal" then w:update_binds("normal") end
end

local M = { pressure = false }
local states = setmetatable({}, { __mode = "k" })
local labels = setmetatable({}, { __mode = "kv" })
local GREEN, YELLOW, PURPLE, GRAY = "#a3be8c", "#d6bb75", "#a99bbd", "#858891"
local wake, resolving_notebook

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

-- Reasons shown on the tab label. These are also the deterministic protections,
-- minus the ones that depend on the tab's role rather than its content.
local function reason(view, s)
    if s.override == "keep" then return "explicit keep loaded" end
    if s.override == "unload" then return end
    if webview.has_load_block(view) then return "page load blocked / lazy restored" end
    if s.capture then return "media permission requested (possible call / capture)" end
    if view.is_loading then return "page loading" end
    if view.is_playing_audio then return "playing audio" end
    local uri = view.uri or ""
    if not uri:match("^https?://") and not uri:match("^file://") then
        return "internal / unsupported page"
    end
end

-- Unload is allowed by default; only determinable state that a reload would
-- genuinely lose is protected. Use ,k for pages that must stay loaded.
local function never(view, s)
    if view.private then return "private tab" end
    if visible(view) then return "tab is visible" end
    return reason(view, s)
end

local function protect(view, s, value)
    if s.reason == value then return end
    s.reason = value
    refresh(view)
end

local function with_file(path, pattern)
    local file = io.open(path, "r")
    if not file then return nil end
    local result
    for line in file:lines() do
        local value = line:match(pattern)
        if value then result = tonumber(value); break end
    end
    file:close()
    return result
end

local function mem_available_mb()
    local kb = with_file("/proc/meminfo", "^MemAvailable:%s+(%d+)")
    return kb and kb / 1024
end

local function install(view)
    if states[view] then return states[view] end
    local s = { last_active = now(), wakened_at = now() }
    states[view] = s
    view:add_signal("destroy", function () states[view] = nil end)
    view:add_signal("load-status", function (_, status)
        if s.lazy_restored and not webview.has_load_block(view) then s.lazy_restored = nil end
        if status == "provisional" then
            protect(view, s, "page loading")
        elseif status == "committed" then
            s.wakened_at = now()
        elseif status == "finished" then
            s.wakened_at = now()
            -- WebKit may still report is_loading inside the signal callback.
            luakit.idle_add(function ()
                if states[view] == s then protect(view, s, reason(view, s)) end
            end)
        end
        refresh(view)
    end)
    view:add_signal("permission-request", function (_, kind)
        if kind == "user-media" then
            -- Do not grant/deny permission here. Protect even if another
            -- handler denies it: there is no capture-ended API in this build.
            s.capture = true
            protect(view, s, reason(view, s))
        end
    end)
    view:add_signal("property::is-playing-audio", function ()
        protect(view, s, reason(view, s))
    end)
    view:add_signal("switched-page", function ()
        s.last_active = now()
        wake(view)
        protect(view, s, reason(view, s))
    end)
    return s
end

wake = function (view)
    local s = states[view]
    if not s or not s.sleeping then return end
    s.sleeping = nil
    s.reason = nil
    s.last_active = now()
    s.wakened_at = now()
    webview.modify_load_block(view, "tmp-auto-unload", false)
    -- Only a load request starts a renderer. adblock keeps its own block until
    -- its web module has run, so a queued location alone cannot start one.
    if webview.has_load_block(view) then view:reload() end
    refresh(view)
end

local function unload(view, s)
    local w = owner(view)
    if not w or s.sleeping then return end
    if never(view, s) then return end
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
    rs.last_active, rs.wakened_at = s.last_active, 0
    webview.modify_load_block(replacement, "tmp-auto-unload", true)
    -- webview's blocked URI/session_state getters expose this saved state to
    -- the session saver without loading the page.
    webview.set_location(replacement, saved)
    w.tabs:insert(index, replacement)
    -- The sleeping tab intentionally starts no renderer; wake() bootstraps one
    -- only when the tab is shown again.
    w:detach_tab(view, false)
    view:destroy()
    refresh(replacement)
end

-- Least recently used first. Firefox's TabUnloader also reweights by the
-- processes and memory each tab holds, but WebKit does not tell the UI process
-- which renderer belongs to which view (view.web_process_id is the PID inside
-- the sandbox PID namespace, 2 for every page), so ordering stays LRU.
local function ranked(list)
    table.sort(list, function (a, b) return a.s.last_active < b.s.last_active end)
    return list
end

local function candidates()
    local list = {}
    for view, s in pairs(states) do
        if not s.sleeping and owner(view) and not never(view, s) then
            list[#list + 1] = { view = view, s = s }
        end
    end
    return list
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
    local unloaded = s.sleeping or (s.lazy_restored and webview.has_load_block(view))
    local title = s.sleeping and escape(s.sleeping.title or s.sleeping.uri) or original_title(tl)
    if unloaded then title = "[z] " .. title end
    local color = unloaded and GRAY or s.override == "keep" and YELLOW or
        s.override == "unload" and PURPLE or s.reason and GREEN
    return color and ('<span foreground="' .. color .. '">' .. title .. '</span>') or title
end
tab.add_signal("build", link_label)
-- Attach before webview init handlers, especially permission handlers that
-- return a decision and stop propagation to later listeners.
widget.add_signal("create", function (view)
    if view.type == "webview" then install(view) end
end)
webview.add_signal("init", function (view) install(view) end)

local function install_window(w, restored)
    local previous = w.tabs[w.tabs:current()]
    for _, view in ipairs(w.tabs.children) do install(view) end
    w:add_signal("mode-entered", function (_, mode)
        if mode.name ~= "insert" and mode.name ~= "normal" then return end
        local view = w.view
        luakit.idle_add(function ()
            if states[view] and owner(view) == w then protect(view, states[view], reason(view, states[view])) end
        end)
    end)
    w.tabs:add_signal("switch-page", function (_, view)
        -- GTK still reports the old current page here. Cache the incoming view
        -- before wake callbacks can resolve w.view to the previous tab.
        w.view = view
        local old = previous
        previous = view
        if old and states[old] then
            local s = states[old]
            s.last_active = now()
            protect(old, s, reason(old, s))
            -- Leave tab switching first; dropping a renderer mid-switch is
            -- not safe from inside the signal.
            if s.override == "unload" and not visible(old) then
                luakit.idle_add(function ()
                    if states[old] == s and not s.sleeping then unload(old, s) end
                end)
            end
        end
        if states[view] then
            states[view].last_active = now()
            wake(view)
            protect(view, states[view], reason(view, states[view]))
        end
    end)
    if restored then
        for index, view in ipairs(w.tabs.children) do
            local s = states[view]
            protect(view, s, reason(view, s))
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
        for i, view in ipairs(w.tabs.children) do
            states[view].lazy_restored = webview.has_load_block(view)
            restore_metadata(view, win.open[i])
        end
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
    s.override, s.last_active = value, now()
    if value == "keep" then wake(view) end
    protect(view, s, reason(view, s))
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
    { ":unload-status", "Explain why this tab is kept loaded.", function (w)
        local s = states[w.view]
        if not s then return end
        local idle = math.floor((now() - s.last_active) / 60)
        local loaded = 0
        for view, other in pairs(states) do
            if not other.sleeping and owner(view) then loaded = loaded + 1 end
        end
        local memory = M.available and string.format("%.0f MiB free%s", M.available,
            M.pressure and ", memory pressure" or "") or "memory unknown"
        w:notify(string.format("override: %s; %s; idle %d/%d min; tabs %d/%d; %s",
            s.override or "default", s.sleeping and "unloaded" or reason(w.view, s) or
            (visible(w.view) and "visible" or "eligible"), idle,
            math.floor(setting("idle_timeout")), loaded, math.floor(setting("max_loaded")), memory))
    end },
})

local function check()
    local t = now()
    local idle_limit = setting("idle_timeout") * 60
    local grace = setting("wake_grace") * 60
    local max_loaded = setting("max_loaded")

    local available = mem_available_mb()
    if available then
        -- Hysteresis: enter pressure below the low watermark, leave it only
        -- after recovering past the high one, so long builds do not thrash.
        if M.pressure then
            if available >= setting("memory_high_mb") then M.pressure = false end
        elseif available < setting("memory_low_mb") then
            M.pressure = true
        end
    end
    M.available = available

    local loaded = 0
    for view, s in pairs(states) do
        if not s.sleeping and owner(view) then
            if visible(view) then s.last_active = t end
            loaded = loaded + 1
            protect(view, s, reason(view, s))
        end
    end

    local over_cap = max_loaded > 0 and loaded > max_loaded
    for _, c in ipairs(ranked(candidates())) do
        local view, s = c.view, c.s
        local due = s.override == "unload"
        if not due and t - (s.wakened_at or 0) >= grace then
            due = t - s.last_active >= idle_limit or M.pressure or over_cap
        end
        if due then
            unload(view, s)
            -- One tab per check keeps bursts from cascading.
            return
        end
    end
end

local poll = timer { interval = 5000 }
poll:add_signal("timeout", check)
poll:start()
-- Exposed for tests and for manual triggering; the timer drives it normally.
M.timer, M.check = poll, check
return M
