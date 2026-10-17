local webview = require("webview")
local window = require("window")
local modes = require("modes")

local pending = {}

modes.new_mode("media-permission", {
    enter = function (w, prompt)
        w:set_input()
        w.view.can_focus = false
        w.win:focus()
        w:warning(prompt .. " [y/n]", false)
    end,
    leave = function (w)
        local request = pending[w]
        pending[w] = nil
        w:set_prompt()
        if request then request.respond(false) end
    end,
})

local function answer(w, allow)
    local request = pending[w]
    pending[w] = nil
    w:set_mode()
    if request then request.respond(allow) end
end

modes.add_binds("media-permission", {
    { "y", "Allow microphone or camera access.", function (w) answer(w, true) end },
    { "n", "Deny microphone or camera access.", function (w) answer(w, false) end },
    { "<Escape>", "Deny microphone or camera access.", function (w) answer(w, false) end },
})

window.add_signal("init", function (w)
    w:add_signal("close", function ()
        if pending[w] then w:set_mode() end
    end)
end)

webview.add_signal("init", function (view)
    local function cancel()
        for w, request in pairs(pending) do
            if request.view == view then w:set_mode() end
        end
    end
    view:add_signal("property::uri", cancel)
    view:add_signal("load-status", function (_, status)
        if status == "provisional" then cancel() end
    end)
    view:add_signal("crashed", cancel)
    view:add_signal("destroy", cancel)

    view:add_signal("permission-request", function (v, kind, request)
        if kind ~= "user-media" then return end

        local devices = {}
        if request.audio then devices[#devices + 1] = "microphone" end
        if request.video then devices[#devices + 1] = "camera" end
        if #devices == 0 then return false end

        return function (respond)
            local w = webview.window(v)
            if not w or w.view ~= v or pending[w] then
                respond(false)
                return
            end
            pending[w] = { view = v, respond = respond }
            w:set_mode("media-permission",
                "Allow " .. v.uri .. " to access your " .. table.concat(devices, " and ") .. "?")
        end
    end)
end)
