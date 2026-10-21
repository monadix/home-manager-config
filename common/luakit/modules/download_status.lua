local downloads = require("downloads")
local window = require("window")

local samples = setmetatable({}, { __mode = "k" })

local function size(bytes)
    local units = { "B", "KiB", "MiB", "GiB", "TiB" }
    local unit = 1
    while bytes >= 1024 and unit < #units do
        bytes, unit = bytes / 1024, unit + 1
    end
    return string.format(unit == 1 and "%.0f %s" or "%.1f %s", bytes, units[unit])
end

local function update()
    local count, received, total, speed = 0, 0, 0, 0
    local known_total, measured_speed = true, false
    local now = luakit.time()
    for d in pairs(downloads.get_all()) do
        if d.status == "created" or d.status == "started" then
            count = count + 1
            local current = d.current_size or 0
            local expected = d.total_size or 0
            received = received + current
            total = total + expected
            if expected <= 0 then known_total = false end

            local previous = samples[d]
            if previous and now > previous.time then
                speed = speed + math.max(0, current - previous.size) / (now - previous.time)
                measured_speed = true
            end
            samples[d] = { size = current, time = now }
        else
            samples[d] = nil
        end
    end

    local text = ""
    if count > 0 then
        text = string.format("%d↓ %s", count, size(received))
        if known_total and total > 0 then
            text = text .. string.format(" / %s (%d%%)", size(total),
                math.min(100, math.floor(received / total * 100)))
        end
        if measured_speed then text = text .. " · " .. size(speed) .. "/s" end
    end
    for _, w in pairs(window.bywidget) do
        w.sbar.r.downloads.text = text
    end
end

-- The built-in downloads timer runs every 300 ms, including a final idle tick.
-- Its status-tick signal fires after it writes the original count-only label.
downloads.add_signal("status-tick", update)
window.add_signal("init", update)

return { update = update }
