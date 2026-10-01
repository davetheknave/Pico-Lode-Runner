-- tiles/sprites
--[[$const]] GOLD_TILE = 24
--[[$const]] PLAYER_START_TILE = 25
--[[$const]] ENEMY_SPAWN_TILE = 26
--[[$const]] LADDER_TILE = 20
--[[$const]] SHIMMY_TILE = 22
--[[$const]] BRICK_TILE = 33
--[[$const]] ONE_WAY_BRICK = 18
--[[$const]] KEY_TILE = 28
--[[$const]] DOOR_TILE = 27

Level = {}
Level.__index = Level

function Level:new(x, y)
    local instance = setmetatable(
        {
            mapX = x,
            mapY = y,
            bricks = {},
            gold = 0
        }, self
    )
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
                player:move_to(Vector:new(x * 8, y * 8))
                player:reset()
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
                enemy:move_to(Vector:new(x * 8, y * 8))
                enemies[#enemies + 1] = enemy
                index += 1
            end
        end
    end
end

function Level:show_secret_ladders()
    for y = self.mapY, self.mapY + 15 do
        for x = self.mapX, self.mapX + 15 do
            local maptile = mget(x, y)
            if maptile == LADDER_TILE + 1 then
                mset(x, y, LADDER_TILE)
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
    local maptile = mget(pos:unpack())
    if maptile == BRICK_TILE then
        for b in all(self.bricks) do
            if b[1] == pos.x and b[2] == pos.y then
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
        self:show_secret_ladders()
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
            -- Beginning
            if b[3] <= 5 then
                mset(b[1], b[2], BRICK_TILE + b[3])
            elseif b[3] >= (BRICK_END - 5) then
                mset(b[1], b[2], BRICK_TILE + BRICK_END - b[3])
            end

            if b[3] >= BRICK_END then
                b[3] = -1
            else
                b[3] += 1 -- tick up
            end
        end
    end
end

function Level:draw()
    map(self.mapX, self.mapY, self.mapX * 8, self.mapY * 8, 16, 16, 0x8F)
end
