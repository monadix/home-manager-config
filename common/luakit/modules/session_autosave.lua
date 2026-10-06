local session = require("session")
local window = require("window")
local webview = require("webview")

local dirty = false
local autosave = timer { interval = 60000 }

local function mark_dirty()
    dirty = true
    -- Further changes must not postpone the pending save.
    if not autosave.started then
        autosave:start()
    end
end

local function save()
    if dirty then
        session.save()
        dirty = false
    end
    if autosave.started then
        autosave:stop()
    end
end

autosave:add_signal("timeout", save)

window.add_signal("init", function (w)
    mark_dirty()
    for _, signal in ipairs {
        "page-added", "page-removed", "page-reordered", "switch-page"
    } do
        w.tabs:add_signal(signal, mark_dirty)
    end

    w:add_signal("close", function ()
        local count = 0
        for _ in pairs(window.bywidget) do count = count + 1 end
        if count == 1 then
            save()
        else
            mark_dirty()
        end
    end)
end)

webview.add_signal("init", function (view)
    view:add_signal("property::uri", mark_dirty)
    view:add_signal("load-status", function (_, status)
        if status == "committed" then mark_dirty() end
    end)
end)

return autosave
