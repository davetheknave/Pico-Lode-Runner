Vector = {
    x = 0, y = 0
}

Vector.__index = Vector

function Vector:unpack()
    return self.x, self.y
end

Vector.__len = function(_)
    return 2
end

function Vector:new(xValue, yValue)
    local instance = setmetatable({ x = xValue or 0, y = yValue or 0 }, Vector)
    return instance
end

function Vector:__tostring()
    return "(" .. tostring(self.x) .. "," .. tostring(self.y) .. ")"
end

function Vector:copy()
    return Vector:new(self.x, self.y)
end

function manhattan_distance(pos1, pos2)
    return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)
end

function distance(pos1, pos2)
    return sqrt(distance2(pos1, pos2))
end

function distance2(pos1, pos2)
    return abs(pos1.x - pos2.x) ^ 2 + abs(pos1.y - pos2.y) ^ 2
end

function Vector:__add(pos1, pos2)
    return Vector:new(pos1.x + pos2.x or pos2[1], pos1.y + pos2.y or pos2[2])
end
