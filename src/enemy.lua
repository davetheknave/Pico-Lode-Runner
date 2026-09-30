Enemy = {}
Enemy.__index = Enemy
setmetatable(Enemy, { __index = Character })

function Enemy:new(name)
    local instance = Character:new()
    setmetatable(instance, self)
    instance.sprite = 49
    instance.name = name
    return instance
end

function Enemy:check_path_to_player()
    local myy = round(self.position.y / 8)
    for x = round(self.position.x / 8), round(player.position.x / 8), (self.position.x < player.position.x and 1 or -1) do
        local next_tile = mget(x, myy)
        -- printh(x .. "," .. myy .. ":" .. next_tile)
        if next_tile != LADDER_TILE and next_tile != SHIMMY_TILE then
            local next_ground = mget(x, myy + 1)
            if next_ground == 0 or next_ground == GOLD_TILE then
                return false
            end
        end
    end
    return true
end

-- This will actually be the ai, rather than input
function Enemy:get_input()
    self.dx = 0
    self.dy = 0
    -- Rule 1: get player if on same level
    if abs(player.position.y - self.position.y) <= 4 and self:check_path_to_player() then
        if self.position.x - player.position.x > 0 and self.left_allowed then
            self.dx = -SPEED
        elseif self.position.x - player.position.x < 0 and self.right_allowed then
            self.dx = SPEED
        end
    end
    if self.dx > 0 then
        self.facing_left = false
    elseif self.dx < 0 then
        self.facing_left = true
    end
end
