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
        if next_tile != LADDER_TILE and next_tile != SHIMMY_TILE then
            local next_ground = mget(x, myy + 1)
            if (next_ground == 0 and (myy < (level.mapY + 15))) or next_ground == GOLD_TILE then
                return false
            end
        end
    end
    return true
end

function Enemy:get_disembark_points(vector)
    if mget(vector:unpack()) == LADDER_TILE then
        return self:search_ladder(vector)
    else
        return {}
    end
end

function Enemy:search_ladder(vector)
    local function add_disembark_points(point_collection, point)
        for xo = -1, 1 do
            local disembark_point = point + Vector:new(xo, 0)
            local checktile = not fget(mget(disembark_point:unpack()), COLLISION_FLAG)
            local ground_is_bottom = (disembark_point.y + 1) > (level.mapY + 16)
            local ground_is_solid = fget(mget(disembark_point.x, disembark_point.y + 1), COLLISION_FLAG)
            local is_valid_disembark_point = checktile and (ground_is_bottom or ground_is_solid)
            if is_valid_disembark_point then
                add(point_collection, disembark_point)
                debug.color = 15
                debug.sprite_point(disembark_point:unpack())
                debug.color = DEBUG_DEFAULT_COLOR
            else
                debug.color = 14
                debug.sprite_point(disembark_point:unpack())
                debug.color = DEBUG_DEFAULT_COLOR
            end
        end
    end
    local output = {}
    local current_vector = vector:copy()
    local current_tile = mget(vector:unpack())
    -- Check below ladder
    while current_tile == LADDER_TILE and current_vector.y <= (level.mapY + 16) do
        add_disembark_points(output, current_vector)
        current_vector.y += 1
        current_tile = mget(current_vector:unpack())
    end
    -- Check above ladder
    current_vector.y = vector.y
    while current_tile == LADDER_TILE and current_vector.y >= level.mapY do
        add_disembark_points(output, current_vector)
        current_vector.y -= 1
        current_tile = mget(current_vector:unpack())
    end
    return output
end

-- This will actually be the ai, rather than input
function Enemy:get_input()
    self.dx = 0
    self.dy = 0
    -- Rule 1: get player if on same level
    if abs(player.position.y - self.position.y) <= 4 and self:check_path_to_player() then
        debug.print("C", self.position.x, self.position.y)
        if self.position.x - player.position.x > 0 and self.left_allowed then
            self.dx = -SPEED
        elseif self.position.x - player.position.x < 0 and self.right_allowed then
            self.dx = SPEED
        end
    else
        -- Rule 2: Get to the player's y level
        local best_route = nil
        local best_score = nil
        -- A destination needs a vector and a move direction
        -- Check down
        if self.down_allowed then
            for y = self.map_pos.y, 15 do
                local tile = mget(self.map_pos.x, y)
                if not fget(tile, COLLISION_FLAG) or tile == ONE_WAY_BRICK then
                    debug.sprite_point(self.map_pos.x, y)
                    for p in all(self:get_disembark_points(Vector:new(self.map_pos.x, y))) do
                        local score = player.map_pos.y - p.y
                        if (score < 0) score *= -100
                        if not best_route or score < best_score then
                            best_route = "down"
                            best_score = score
                        end
                    end
                else
                    break
                end
            end
        end
        -- Check up
        if self.up_allowed then
            for y = 0, self.map_pos.y do
                debug.sprite_point(self.map_pos.x, y, 3)
                local tile = mget(self.map_pos.x, y)
                if not fget(tile, COLLISION_FLAG) or tile == ONE_WAY_BRICK then
                    for p in all(self:get_disembark_points(Vector:new(self.map_pos.x, y))) do
                        local score = player.map_pos.y - p.y
                        if (score < 0) score *= -100
                        if not best_route or score < best_score then
                            best_route = "up"
                            best_score = score
                        end
                    end
                else
                    break
                end
            end
        end
        -- Check left
        if self.left_allowed then
            for x = 0, self.map_pos.x do
                debug.sprite_point(x, self.map_pos.y, 3)
                local tile = mget(x, self.map_pos.y)
                if not fget(tile, COLLISION_FLAG) or tile == ONE_WAY_BRICK then
                    for p in all(self:get_disembark_points(Vector:new(x, self.map_pos.y))) do
                        local score = player.map_pos.y - p.y
                        if (score < 0) score *= -100
                        if not best_route or score < best_score then
                            best_route = "left"
                            best_score = score
                        end
                    end
                else
                    break
                end
            end
        end
        -- Check right
        if self.right_allowed then
            for x = self.map_pos.x, 15 do
                debug.sprite_point(x, self.map_pos.y, 3)
                local tile = mget(x, self.map_pos.y)
                if not fget(tile, COLLISION_FLAG) or tile == ONE_WAY_BRICK then
                    for p in all(self:get_disembark_points(Vector:new(x, self.map_pos.y))) do
                        local score = player.map_pos.y - p.y
                        if (score < 0) score *= -100
                        if not best_route or score < best_score then
                            best_route = "right"
                            best_score = score
                        end
                    end
                else
                    break
                end
            end
        end
        -- Actually set movement
        if best_route == "down" then
            debug.print("D", self.position.x, self.position.y)
            self.dy = SPEED
        elseif best_route == "up" then
            debug.print("U", self.position.x, self.position.y)
            self.dy = -SPEED
        elseif best_route == "left" then
            debug.print("L", self.position.x, self.position.y)
            self.dx = -SPEED
        elseif best_route == "right" then
            debug.print("R", self.position.x, self.position.y)
            self.dx = SPEED
        end
    end

    -- Finalize
    if self.dx > 0 then
        self.facing_left = false
    elseif self.dx < 0 then
        self.facing_left = true
    end
end
