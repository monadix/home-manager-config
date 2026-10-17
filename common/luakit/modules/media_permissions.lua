local webview = require("webview")

webview.add_signal("init", function (view)
    view:add_signal("permission-request", function (v, kind, request)
        if kind ~= "user-media" then return end

        local devices = {}
        if request.audio then devices[#devices + 1] = "microphone" end
        if request.video then devices[#devices + 1] = "camera" end
        if #devices == 0 then return false end

        return function (respond)
            respond(luakit.confirm(v,
                "Allow access to your " .. table.concat(devices, " and ") .. "?",
                "Page: " .. v.uri))
        end
    end)
end)
