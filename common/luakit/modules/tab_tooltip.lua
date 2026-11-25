-- Show the full URI in a tooltip when hovering over a tab.
local tab = require("lousy.widget.tab")
local escape = require("lousy.util").escape

tab.add_signal("build", function (tl, view)
    local function update (v)
        tl.widget.tooltip = escape(v.uri or "")
    end
    view:add_signal("property::uri", update)
    tl.widget:add_signal("destroy", function ()
        view:remove_signal("property::uri", update)
    end)
    update(view)
end)
