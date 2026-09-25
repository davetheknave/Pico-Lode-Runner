-- tiles/sprites
--[[$const]] GOLD_TILE = 24
--[[$const]] PLAYER_START_TILE = 25
--[[$const]] ENEMY_SPAWN_TILE = 26
--[[$const]] LADDER_TILE = 20
--[[$const]] SHIMMY_TILE = 22
--[[$const]] BRICK_TILE = 33

Level = {
    mapX = 0,
    mapY = 0,
    bricks = {},
    gold = 0
}
Level.__index = Level

function Level:new(x, y)
    local instance = setmetatable({}, self)
    self.mapX = x
    self.mapY = y
    return instance
end

function Level:index_bricks()
    for y = self.mapY, self.mapY + 15 do
        for x = self.mapX, self.mapX + 15 do
            local maptile = mget(x, y)
            if maptile == BRICK_TILE then
                self.bricks[#self.bricks + 1] = { x, y, -1 }
            end
        end
    end
end

function Level:place_player(player)
    for y = self.mapY, self.mapY + 15 do
        for x = self.mapX, self.mapX + 15 do
            local maptile = mget(x, y)
            if maptile == PLAYER_START_TILE then
                mset(x, y, 0)
                player:move_to(x * 8, y * 8)
                return
            end
        end
    end
end

function Level:place_enemies(enemies)
    local index = 0
    for y = self.mapY, self.mapY + 15 do
        for x = self.mapX, self.mapX + 15 do
            local maptile = mget(x, y)
            if maptile == ENEMY_SPAWN_TILE then
                mset(x, y, 0)
                local enemy = Enemy:new(index)
                enemy:move_to(x * 8, y * 8)
                enemies[#enemies + 1] = enemy
                index += 1
            end
        end
    end
end

function Level:count_remaining_gold()
    for y = self.mapY, self.mapY + 15 do
        for x = self.mapX, self.mapX + 15 do
            if mget(x, y) == GOLD_TILE then
                self.gold += 1
            end
        end
    end
end

function Level:zap_block(pos)
    local maptile = mget(unpack(pos))
    if maptile == BRICK_TILE then
        for b in all(self.bricks) do
            if b[1] == pos[1] and b[2] == pos[2] then
                b[3] = 0
                return
            end
        end
    end
end

--- Removes gold from the level
--- @return whether or not the player has taken all gold in the level
function Level:get_gold(x, y)
    mset(x, y, 0)
    self.gold -= 1
    if self.gold <= 0 then
        return true
    else
        return false
    end
end

function Level:init()
    self:index_bricks()
    self:count_remaining_gold()
end

function Level:update()
    -- update zapped bricks
    for b in all(self.bricks) do
        if b[3] != -1 then
            -- Zapping
            if b[3] <= 5 then
                mset(b[1], b[2], BRICK_TILE + b[3])
            elseif b[3] >= BRICK_END then
                mset(b[1], b[2], BRICK_TILE + 5 - (b[3] - BRICK_END) + 1)
            end
            -- Unzapping
            if b[3] > BRICK_END + 5 then
                b[3] = -1
                return
            end
            b[3] += 1 -- tick up
        end
    end
end

function Level:draw()
    map(self.mapX, self.mapY, self.mapX * 8, self.mapY * 8, 16, 16, 0x8F)
end
