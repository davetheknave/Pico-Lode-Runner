effects = {
    effects = {}
}

Effect = {
    draw = function() end,
    duration = 0
}
Effect.__index = Effect
function Effect:new()
    local instance = setmetatable({}, self)
    return instance
end

function effects:round_wipe(speed, callback)
    local e = Effect:new()
    e.duration = 91
    e.draw = function(xOffset, yOffset)
        poke(0x5f34, 0x2)
        e.duration += speed > 0 and -speed or speed
        circfill(xOffset + 64, yOffset + 64, speed > 0 and (91 - e.duration) or e.duration, 0 | 0x1800)
        if e.duration <= 0 then
            callback()
        end
    end
    add(effects.effects, e)
    return e
end

function effects:horizontal_wipe(speed, callback)
    local e = Effect:new()
    e.duration = 64
    e.draw = function(self, xOffset, yOffset)
        poke(0x5f34, 0x2)
        e.duration += speed > 0 and -speed or speed
        local position = speed > 0 and (64 - e.duration) or e.duration
        rectfill(xOffset + 0, yOffset + 64 - position, xOffset + 128, yOffset + 64 + position, 0 | 0x1800)
        if e.duration <= 0 then
            callback()
        end
    end
    add(effects.effects, e)
    return e
end

function effects:draw(xOffset, yOffset)
    for e in all(self.effects) do
        e:draw(xOffset, yOffset)
    end
    filter_inplace(self.effects, function(e) return e.duration > 0 end)
end
