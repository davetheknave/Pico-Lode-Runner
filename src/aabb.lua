-- returns true if colliding, false if not
function aabb(x1, y1, w1, h1, x2, y2, w2, h2)
    return (x1 < x2 + w2)
            and (x1 + w1 > x2)
            and (y1 < y2 + h2)
            and (y1 + h1 > y2)
end

function aabb_sprite(pos1, pos2)
    return aabb(pos1.x * 8, pos1.y * 8, 8, 8, pos2.x * 8, pos2.y * 8, 8, 8)
end

function manhattan_distance(pos1, pos2)
    return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)
end

function distance(pos1, pos2)
    return sqrt(abs(pos1.x - pos2.x) ^ 2 + abs(pos1.y - pos2.y) ^ 2)
end
