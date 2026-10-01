pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
package={loaded={},_c={}}
package._c["debug/gizmos"]=function()
--[[$const]] DEBUG_DEFAULT_COLOR = 2

debug = {
    color = DEBUG_DEFAULT_COLOR,
    points = {},
    lines = {},
    arrows = {},
    rects = {},
    text = {}
}

-- types of things to draw: points/circles, arrows, lines, rect, text

function debug.point(x, y)
    add(debug.points, { x, y, debug.color })
end
function debug.sprite_point(x, y)
    debug.point(x * 8 + 3, y * 8 + 3)
end

function debug.line(x, y, x2, y2)
    add(debug.lines, { x, y, x2, y2, debug.color })
end
function debug.arrow(x, y, x2, y2)
    add(debug.arrows, { x, y, x2, y2, debug.color })
end
function debug.rect(x, y, x2, y2)
    add(debug.rects, { x, y, x2, y2, debug.color })
end
function debug.print(text, x, y)
    add(debug.text, { text, x, y, debug.color })
end

function debug.draw()
    for p in all(debug.points) do
        circ(p[1], p[2], 1, p[3])
    end
    for l in all(debug.lines) do
        line(l[1], l[2], l[3], l[4], l[5])
    end
    for a in all(debug.arrows) do
        line(a[1], a[2], a[3], a[4], a[5])
        circ(a[3], a[4], 2, a[5])
    end
    for r in all(debug.rects) do
        rect(r[1], r[2], r[3], r[4], r[5])
    end
    for t in all(debug.text) do
        print(t[1], t[2], t[3], t[4])
    end
    debug.points = {}
    debug.lines = {}
    debug.arrows = {}
    debug.rects = {}
    debug.text = {}
end
end
package._c["vector"]=function()
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

function Vector.__add(pos1, pos2)
    return Vector:new(pos1.x + pos2.x or pos2[1], pos1.y + pos2.y or pos2[2])
end

function Vector:scale(scalar)
    return Vector:new(self.x * scalar, self.y * scalar)
end
end
package._c["utilities"]=function()
function round(value)
	return value >= 0 and flr(value + 0.5) or ceil(value - 0.5)
end

function filter_inplace(arr, func)
	local new_index = 1
	local size_orig = #arr
	for old_index, v in ipairs(arr) do
		if func(v, old_index) then
			arr[new_index] = v
			new_index = new_index + 1
		end
	end
	for i = new_index, size_orig do
		arr[i] = nil
	end
end
end
package._c["aabb"]=function()
-- returns true if colliding, false if not
function aabb(x1, y1, w1, h1, x2, y2, w2, h2)
    return (x1 < x2 + w2)
            and (x1 + w1 > x2)
            and (y1 < y2 + h2)
            and (y1 + h1 > y2)
end

function aabb_sprite(pos1, pos2)
    return aabb(pos1.x, pos1.y, 8, 8, pos2.x, pos2.y, 8, 8)
end
end
package._c["animator"]=function()
function make_animation(a)
    local output = a or {
        frames = {}
    }
    function output:start()
        self.dt = 0
    end
    local function draw_frame(sprite_offset, frame, x, y, flip)
        -- not equals is used as exclusive or, to ensure double flip is just not flipped
        spr(frame.sprite + sprite_offset, x, y + (frame.bounce or 0), 1, 1, not flip != not frame.flip)
    end
    function output:draw(sprite_offset, x, y, flip)
        self.dt = self.dt or 0
        self.dt += 1 / 30
        local index = flr(self.dt / ANIMATION_RATE * 30) % #self.frames + 1
        local frame = self.frames[index]
        draw_frame(sprite_offset, frame, x, y, flip)
    end
    return output
end
end
package._c["palettes"]=function()
--[[
COLOR LIST: ALL CAPS MEANS DO NOT CHANGE
black, white, GOLD, GOLD-SHADE
SKIN, helmet, shirt, pants
robot-skin, robot-helm, robot-shirt
brick1, brick2
bg-bottom, bg-top, bg-accent
]]

palettes = {
    [0] = {
	    [0] = -16, 7, 10, 9, -- Black, white, gold, gold-shade
		15, 2, 14, 9, -- Skin, Helmet, Shirt, Pants
		6, -11, -10, -- RSkin, RHelmet, RShirt
		-12, -10, -- brick1, brick2
		-15, -14, -4 -- bg1, bg2, bg3
    },
    [1] = {
	    [0] = -16, 7, 10, 9, -- Black, white, gold, gold-shade
		15, 2, 14, 9, -- Skin, Helmet, Shirt, Pants
		6, -11, -10, -- RSkin, RHelmet, RShirt
		-12, -10, -- brick1, brick2
		-15, -14, -4 -- bg1, bg2, bg3
    },

}
end
package._c["character"]=function()
-- character states
--[[$const]] STATE_STANDING = 1
--[[$const]] STATE_WALKING = 2
--[[$const]] STATE_SHOOTING = 3
--[[$const]] STATE_CLIMBING = 4
--[[$const]] STATE_SHIMMYING = 5
--[[$const]] STATE_FALLING = 6
--[[$const]] STATE_DYING = 7
--[[$const]] STATE_LADDER = 8
-- Other constants
--[[$const]] SHOOT_DURATION = 0.5

Character = {
	speed = 0,
	dx = 0,
	dy = 0,
	state = STATE_STANDING,
	facing_left = false,
	-- animation = STATE_STANDING,
	frame = 0,
	sprite = 1, -- 1 for player, 49 for enemy
	down_allowed = false,
	up_allowed = false,
	left_allowed = false,
	right_allowed = false,
	shoot_left_allowed = false,
	shoot_right_allowed = false
}
Character.__index = Character

Character.animations = {
	[STATE_STANDING] = make_animation({
		frames = { { sprite = 0 } }
	}),
	[STATE_WALKING] = make_animation({
		frames = {
			{ sprite = 1, bounce = -1 },
			{ sprite = 2, bounce = 0 },
			{ sprite = 3, bounce = -1 },
			{ sprite = 2, bounce = 0 }
		}
	}),
	[STATE_SHOOTING] = make_animation({
		frames = { { sprite = 4 } }
	}),
	[STATE_CLIMBING] = make_animation({
		frames = { { sprite = 6 }, { sprite = 5 }, { sprite = 6 }, { sprite = 5, flip = true } }
	}),
	[STATE_SHIMMYING] = make_animation({
		frames = { { sprite = 7 }, { sprite = 8 } }
	}),
	[STATE_FALLING] = make_animation({
		frames = { { sprite = 9 } }
	}),
	[STATE_DYING] = make_animation({
		frames = { { sprite = 9 }, { sprite = 10 }, { sprite = 11 } },
		oneshot = true
	}),
	[STATE_LADDER] = make_animation({
		frames = { { sprite = 6 } }
	})
}

function Character:new()
	local instance = setmetatable({}, self)
	instance.position = Vector:new()
	return instance
end

function Character:get_tile()
	return Vector:new(round(self.position.x / 8), round(self.position.y / 8))
end

function Character:get_floor()
	return Vector:new(round(self.position.x / 8), flr(self.position.y / 8 + 1))
end

function Character:get_ceiling()
	return Vector:new(round(self.position.x / 8), ceil(self.position.y / 8 - 1))
end

function Character:get_left()
	return Vector:new(ceil(self.position.x / 8 - 1), round(self.position.y / 8))
end

function Character:get_right()
	return Vector:new(flr(self.position.x / 8 + 1), round(self.position.y / 8))
end

function Character:get_floor_left()
	local floor = self:get_floor()
	floor.x -= 1
	return floor
end

function Character:get_floor_right()
	local floor = self:get_floor()
	floor.x += 1
	return floor
end

function Character:move_to(position)
	self.position = position:copy()
end

function Character:check_mobility()
	-- If the character is shooting, they can't move
	if self.state == STATE_SHOOTING then
		if time() - self.last_state_change >= SHOOT_DURATION then
			self.state = STATE_STANDING
		end
	end
	if self.state == STATE_SHOOTING then
		self.left_allowed = false
		self.right_allowed = false
		self.down_allowed = false
		self.up_allowed = false
		return
	end
	-- Get surroundings
	local self_tile = mget(self.map_pos:unpack())
	local below_pos = self:get_floor()
	local below_tile = mget(below_pos:unpack())
	local above_pos = self:get_ceiling()
	local above_tile = mget(above_pos:unpack())
	local left_pos = self:get_left()
	local left_tile = mget(self.map_pos.x - 1, self.map_pos.y)
	local right_pos = self:get_right()
	local right_tile = mget(self.map_pos.x + 1, self.map_pos.y)

	local touching_ladder = self_tile == LADDER_TILE or below_tile == LADDER_TILE
	local grounded = self:check_grounded()

	-- Check movement

	self.down_allowed = not grounded
	if below_tile == LADDER_TILE or grounded then
		self.state = STATE_STANDING
	else
		self.state = STATE_FALLING
	end

	self.up_allowed = false
	if touching_ladder then
		if not grounded then
			self.state = STATE_CLIMBING
		end
		if not ((self.position.y % 8 == 0) and not (self_tile == LADDER_TILE)) then
			self.up_allowed = true
		else
			self.state = STATE_STANDING
		end
	end
	if fget(above_tile, COLLISION_FLAG) or above_pos.y < level.mapY then
		self.up_allowed = false
	end
	if self_tile == SHIMMY_TILE and self.position.y % 8 == 0 then
		self.up_allowed = false
		self.state = STATE_SHIMMYING
	end

	self.left_allowed = not fget(mget(left_pos:unpack()), COLLISION_FLAG) and not (left_pos.x < level.mapX)
	self.right_allowed = not fget(mget(right_pos:unpack()), COLLISION_FLAG) and not (right_pos.x > level.mapX + 15)

	self.shoot_left_allowed = mget(self:get_floor_left():unpack()) == BRICK_TILE and not fget(left_tile, BLOCK_ZAP_FLAG)
	self.shoot_right_allowed = mget(self:get_floor_right():unpack()) == BRICK_TILE and not fget(right_tile, BLOCK_ZAP_FLAG)
end

function Character:get_input()
	printh("This shouldn't run")
end

function Character:check_grounded()
	local floor = self:get_floor()
	local floor_tile = mget(floor:unpack())
	return flr(floor.y) >= (level.mapY + 16) or (fget(floor_tile, COLLISION_FLAG) and not (floor_tile == ONE_WAY_BRICK)) or self:check_standing_on_enemy()
end

function Character:check_standing_on_enemy()
	for e in all(enemies) do
		if abs(self.position.x - e.position.x) <= 4 then
			local vDistance = e.position.y - self.position.y
			if vDistance <= 8 and vDistance >= 7 then
				return true
			end
		end
	end
	return false
end

function Character:update_movement()
	-- the game nudges the player towards the center of the axis they are walking on
	if self.dx != 0 and self.dy != 0 then
		printh("Trying to move diagonally")
	else
		if self.dx != 0 or self.state == STATE_SHOOTING then
			if self.position.y % 8 >= 4 then
				self.dy = min(self.position.y % 8, self.speed)
			else
				self.dy = max(-(self.position.y % 8), -self.speed)
			end
		end
		if self.dy != 0 or self.state == STATE_FALLING or self.state == STATE_SHOOTING then
			if self.position.x % 8 >= 4 then
				self.dx = min(self.position.x % 8, self.speed)
			else
				self.dx = max(-(self.position.x % 8), -self.speed)
			end
		end
	end

	-- Resolve movement
	if self.state == STATE_FALLING then
		self.dy = self.speed
	end

	self.position.x += self.dx
	self.position.y += self.dy
	if self:check_grounded() then
		self.position.y = flr(self.position.y / 8) * 8
	end
	if (self.dx != 0 or self.dy != 0) then
		if self.state == STATE_STANDING then
			self.state = STATE_WALKING
		elseif self.state == STATE_LADDER then
			self.state = STATE_CLIMBING
		end
	else
		if self.state == STATE_WALKING then
			self.state = STATE_STANDING
		elseif self.state == STATE_CLIMBING then
			self.state = STATE_LADDER
		end
	end
end

function Character:collide(other)
end

function Character:change_state(new_state)
	self.state = new_state
	self.animations[self.state]:start()
end

function Character:update()
	self.map_pos = self:get_tile()
	self:check_mobility()
	self:get_input()
	self:update_movement()
end

function Character:draw()
	local current_animation = self.animations[self.state]
	current_animation:draw(self.sprite, self.position.x, self.position.y, self.facing_left)
end
end
package._c["player"]=function()
Player = {}
Player.__index = Player
setmetatable(Player, { __index = Character })

function Player:get_input()
	self.dx = 0
	self.dy = 0
	if self.state != STATE_FALLING and self.state != STATE_SHOOTING and self.state != STATE_DYING then
		if not (btn(0) and btn(1)) then
			if self.left_allowed and btn(0) then
				-- left
				self.facing_left = true
				self.dx = -self.speed
			elseif self.right_allowed and btn(1) then
				--right
				self.dx = self.speed
				self.facing_left = false
			end
		end

		-- can't move vertical and horizontal. vertical has priority
		if not (btn(2) and btn(3)) then
			if self.up_allowed and btn(2) then
				-- up
				self.dx = 0
				self.dy = -self.speed
			elseif self.down_allowed and btn(3) then
				-- down
				self.dx = 0
				self.dy = self.speed
			end
		end

		if self.shoot_left_allowed and btn(swapped_controls and 5 or 4) then
			-- O
			self:shoot(true)
			self.facing_left = true
			self.state = STATE_SHOOTING
			self.last_state_change = time()
			self.dx = 0
			self.dy = 0
		elseif self.shoot_right_allowed and btn(swapped_controls and 4 or 5) then
			-- X
			self:shoot(false)
			self.facing_left = false
			self.state = STATE_SHOOTING
			self.last_state_change = time()
			self.dx = 0
			self.dy = 0
		end
	end
	if self.dx != 0 or self.dy != 0 or self.state == STATE_SHOOTING then
		self.has_moved = true
	end
end

function Player:collide(other)
	if manhattan_distance(self.map_pos, other.map_pos) <= .5 then
		lose()
	end
end

function Player:update()
	Character.update(self)
	-- game logic
	local next_pos = self.map_pos
	local next_tile = mget(next_pos:unpack())
	if next_tile == GOLD_TILE and manhattan_distance(self.position:scale(1 / 8), next_pos) <= 0.25 then
		self:get_gold(self.map_pos)
	end
end

function Player:new()
	local instance = Character:new()
	setmetatable(instance, self)
	instance.sprite = 1
	instance.has_moved = false
	instance.speed = SPEED
	return instance
end

function Player:reset()
	self.state = STATE_STANDING
	self.animation = STATE_STANDING
	self.frame = 0
	self.has_moved = false
	self.facing_left = false
end

function Player:draw()
	if self.has_moved then
		Character.draw(self)
	else
		if frame % 8 > 3 then
			Character.draw(self)
		end
	end
	-- debug.color = DEBUG_DEFAULT_COLOR
	-- printh(self.position)
	-- if self.up_allowed then debug.print("U", self.position.x + 3, self.position.y - 8) end
	-- if self.down_allowed then debug.print("D", self.position.x + 3, self.position.y + 8) end
	-- if self.left_allowed then debug.print("L", self.position.x - 5, self.position.y) end
	-- if self.right_allowed then debug.print("R", self.position.x + 8, self.position.y) end
end
end
package._c["enemy"]=function()
Enemy = {}
Enemy.__index = Enemy
setmetatable(Enemy, { __index = Character })

function Enemy:new(name)
    local instance = Character:new()
    setmetatable(instance, self)
    instance.sprite = 49
    instance.name = name
    instance.speed = ENEMY_SPEED
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
            self.dx = -self.speed
        elseif self.position.x - player.position.x < 0 and self.right_allowed then
            self.dx = self.speed
        end
    end
    if self.dx > 0 then
        self.facing_left = false
    elseif self.dx < 0 then
        self.facing_left = true
    end
end
end
package._c["level"]=function()
-- tiles/sprites
--[[$const]] GOLD_TILE = 24
--[[$const]] PLAYER_START_TILE = 1
--[[$const]] ENEMY_SPAWN_TILE = 49
--[[$const]] LADDER_TILE = 20
--[[$const]] SHIMMY_TILE = 22
--[[$const]] BRICK_TILE = 32
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
            elseif b[3] >= (BRICK_END - 15) then
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
end
package._c["gui/window_manager"]=function()
Window = {}
Window.__index = Window

function Window:new(owner)
    local instance = setmetatable({ owner = owner }, self)
    return instance
end

GUI = {
    windows = {},
    xOffset = 0,
    yOffset = 0
}
GUI.__index = GUI

function GUI:new(x, y)
    local instance = setmetatable(
        {
            windows = {},
            xOffset = x,
            yOffset = y
        }, self
    )
    return instance
end

function GUI:close_window()
    deli(self.windows)
end

-- returns true if input shouldn't continue to bubble
function GUI:handle_input()
    if #self.windows > 0 then
        local top = self.windows[#self.windows]
        if btnp(4) then
            if top.onO != nil then
                top.onO()
            end
        elseif btnp(5) then
            if top.onX != nil then
                top.onX()
            end
        elseif btnp(2) then
            if top.onUp != nil then
                top.onUp()
            end
        elseif btnp(3) then
            if top.onDown != nil then
                top.onDown()
            end
        elseif btnp(1) then
            if top.onRight != nil then
                top.onRight()
            end
        elseif btnp(0) then
            if top.onLeft != nil then
                top.onLeft()
            end
        end
        return true
    else
        return false
    end
end

function GUI:draw()
    for w in all(self.windows) do
        if w.draw != nil then
            w.draw()
        end
    end
end
end
package._c["gui/renderer"]=function()
function GUI:draw_window(x, y, w, h)
    local cornerthing = 1
    local outline_color = 0
    local fill_color = 1
    rrectfill(self.xOffset + x, self.yOffset + y, w, h, 1, fill_color)
    rrect(self.xOffset + x, self.yOffset + y, w, h, 1, outline_color)
    circfill(self.xOffset + x, self.yOffset + y, cornerthing, outline_color)
    circfill(self.xOffset + x + w - 1, self.yOffset + y, cornerthing, outline_color)
    circfill(self.xOffset + x, self.yOffset + y + h - 1, cornerthing, outline_color)
    circfill(self.xOffset + x + w - 1, self.yOffset + y + h - 1, cornerthing, outline_color)
end

function GUI:draw_textbox(message, x, y, w, h)
    local padding = 3
    self:draw_window(x, y, w, h)
    print(message, self.xOffset + x + padding, self.yOffset + y + padding)
end

function GUI:draw_list(items, selection, x, y, w, h)
    self:draw_window(x, y, w, h)
    local index = 0
    for i in all(items) do
        print(i, self.xOffset + x + 2 + 4, self.yOffset + y + 7 * index + 2)
        index += 1
    end
    circ(self.xOffset + x + 3, self.yOffset + y + 4 + 7 * selection, 1)
end

function GUI:draw_grid(items, selected, x, y, w, h, cols)
    self:draw_window(x, y, w, h)
    local rows = ceil(#items / cols)
    for row = 1, rows do
        for column = 1, cols do
            local index = (row - 1) * cols + column
            if index <= #items then
                local itemX = self.xOffset + x + (column - 1) * (w - 2) / cols + 2
                local itemY = self.yOffset + y + (row - 1) * (h - 2) / rows + 2
                self:draw_grid_item(items[index], index == selected, itemX, itemY, (w - 2) / cols - 1, (h - 2) / rows - 1)
            end
        end
    end
end

function GUI:draw_grid_item(text, selected, x, y, w, h)
    if selected then
        rrectfill(x, y, w - 1, h - 1, 1, 3)
    else
        rrectfill(x, y, w - 1, h - 1, 1, 4)
    end
    print(text, x + w / 2 - (4 * #text / 2), y + h / 2 - 3, 1)
end

function GUI:make_grid(items, x, y, w, h, onChoose)
    local window = Window:new(self)
    local cols = 4
    window.selected = 0
    window.onX = function() self:close_window() end
    window.onO = function() self:close_window() onChoose(window.selected + 1) end
    window.onUp = function()
        window.selected = window.selected - cols
        if window.selected < 0 then
            window.selected = ceil(#items / cols) * cols + window.selected
        end
        if window.selected >= #items then
            window.selected -= cols
        end
    end
    window.onDown = function()
        window.selected = window.selected + cols
        if window.selected >= #items then
            window.selected = window.selected - ceil(#items / cols) * cols
        end
        if window.selected < 0 then
            window.selected += cols
        end
    end
    window.onLeft = function()
        -- window.selected = (window.selected - 1) % #items
        window.selected = (window.selected - 1) % cols + flr(window.selected / cols) * cols
        if window.selected >= #items then
            window.selected = #items - 1
        end
    end
    window.onRight = function()
        -- window.selected = (window.selected + 1) % #items
        window.selected = (window.selected + 1) % cols + flr(window.selected / cols) * cols
        if window.selected >= #items then
            window.selected = flr(#items / cols) * cols
        end
    end
    window.draw = function() self:draw_grid(items, window.selected + 1, x, y, w, h, cols) end
    add(self.windows, window)
    return window
end

function GUI:make_textbox(message)
    local window = Window:new(self)
    window.onX = function() self:close_window() end
    window.onO = function() self:close_window() end
    window.draw = function() self:draw_bottom_text(message) end
    add(self.windows, window)
    return window
end
end
package._c["gui/lr_widgets"]=function()
function GUI:make_main_menu(choose)
    local levels = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17" }
    local grid = self:make_grid(levels, 2, 20, 124, 106, choose)
    grid.onX = nil
    local old_draw = grid.draw
    local title = "lode runner"
    local style = "\f7\^w\^t\^o!ff"
    grid.draw = function()
        cls(1)
        old_draw()
        print(style .. title, self.xOffset + 64 - (#title / 2 * 8), 4, 0)
    end
end

function GUI:make_yesno(startYes, onYes, onNo)
    local window = Window:new(self)
    window.yes = startYes
    window.onX = function() self:close_window() onNo() end
    window.onO = function() self:close_window() if window.yes then onYes() else onNo() end end
    window.onUp = function() window.yes = not window.yes end
    window.onDown = function() window.yes = not window.yes end
    window.draw = function() self:draw_list({ "yes", "no" }, not window.yes and 1 or 0, 107, 92, 20, 16) end
    add(self.windows, window)
    return window
end

function GUI:draw_bottom_text(message)
    local text_height = 7
    self:draw_textbox(message, 1, 109, 126, text_height * 2 + 4)
end
end
package._c["effects"]=function()
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
end
package._c["noise"]=function()
-- Shiplex Noise
-- Noesis

--sn noise
srand(0)
local s_noise_p = {}
for i = 1, 512 do
    s_noise_p[i] = flr(rnd(256))
end
local s_noise_g = { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, 0 }, { -1, -1 }, { 1, -1 }, { 1, -1 }, { 1, 0 } }
function s_noise_cb(x, y, z)
    local t = .5 - x * x - y * y
    if (t < 0) return 0
    return t ^ 4 * (s_noise_g[z + 1][1] * x + s_noise_g[z + 1][2] * y)
end
function simplex(x, y)
    local g = .2113
    local s = (x + y) * .366
    local i, j = flr(x + s), flr(y + s)
    local t = (i + j) * g
    local x0, y0 = x - (i - t), y - (j - t)
    local i1 = 0
    j1 = 1
    if (x0 > y0) i1 = 1
    j1 = 0
    local x1 = x0 - i1 + g
    local y1 = y0 - j1 + g
    local x2 = x0 - 1 + 2 * g
    local y2 = y0 - 1 + 2 * g
    local u = i & 255
    local v = j & 255
    return 70 * (s_noise_cb(x0, y0, s_noise_p[u + s_noise_p[v + 1]] % 8) + s_noise_cb(x1, y1, s_noise_p[u + i1 + s_noise_p[v + j1 + 1]] % 8) + s_noise_cb(x2, y2, s_noise_p[u + 1 + s_noise_p[v + 2]] % 8))
end
end
package._c["background-shimmer"]=function()
function draw_shimmer(time, offsetX, offsetY)
    local timeScale = 200
    time += timeScale
    local range = 3
    local threshold = abs(((time % timeScale) / timeScale) - 0.5) * 0.5 + 0.3
    for y = 0, 15 do
        for x = 0, 15 do
            local tile = mget(112 + x, 048 + y)
            if simplex((x * 400 * flr(time / 200)), y * 4) > threshold then
                tile += 4
            end
            spr(tile, x * 8 + offsetX, y * 8 + offsetY)
        end
    end
end
end
function require(p)
local l=package.loaded
if (l[p]==nil) l[p]=package._c[p]()
if (l[p]==nil) l[p]=true
return l[p]
end
-- settings
--[[$const]] SPEED = 1
--[[$const]] ENEMY_SPEED = SPEED * 0.5
--[[$const]] ANIMATION_RATE = 4
-- brick lifecycle
--[[$const]] BRICK_END = 252 -- 7 sec * 30 fps * 1.2
-- flags
--[[$const]] COLLISION_FLAG = 0
--[[$const]] KILL_FLAG = 1
--[[$const]] BLOCK_ZAP_FLAG = 2
--[[$const]] VISIBLE_FLAG = 7
-- sounds
--[[$const]] GOLD_SOUND = 63
--[[$const]] SHOOT_SOUND = 62
--[[$const]] DIE_SOUND = 61
--[[$const]] ENEMY_DIE_SOUND = 60

require("debug/gizmos")
require("vector")
require("utilities")
require("aabb")
require("animator")
require("palettes")
require("character")
require("player")
require("enemy")
require("level")
require("gui/window_manager")
require("gui/renderer")
require("gui/lr_widgets")
require("effects")
require("noise")
require("background-shimmer")

player = Player:new()
local gui = GUI:new(0, 0)
frame = 0
level_loaded = false
running = false
current_level_id = 0
swapped_controls = false -- this should be true upon release

levels = {
	0,
	1,
	2,
	3,
	4,
	5,
	6,
	7,
	8,
	9,
	10,
	11,
	12,
	13,
	14,
	15,
	17
}

function player:shoot(left)
	sfx(SHOOT_SOUND)
	if left then
		level:zap_block(player:get_floor_left())
	else
		level:zap_block(player:get_floor_right())
	end
end

function load_level(levelID)
	reload()
	current_level_id = levelID
	enemies = {}
	bricks = {}
	level = Level:new((levels[current_level_id] % 8) * 16, flr(levels[current_level_id] / 8) * 16)
	camera(level.mapX * 8, level.mapY * 8)
	gui.xOffset = level.mapX * 8
	gui.yOffset = level.mapY * 8
	frame = 0
	level:place_player(player)
	level:place_enemies(enemies)
	level:init()
	effects:horizontal_wipe(3, function() running = true end)
	level_loaded = true
	running = false
	menuitem(1, "restart level", function() load_level(current_level_id) end)
end

function _init()
	set_palette(0)
	show_main_menu()
	-- 142 is the O key
	menuitem(2, "🅾️ digs left", swap_controls)
end

function swap_controls(b)
	if b == 112 then
		return false
	else
		swapped_controls = not swapped_controls
		menuitem(2, "🅾️ digs " .. (swapped_controls and "right" or "left"), swap_controls)
		return true
	end
end

function show_main_menu()
	menuitem(1)
	gui:make_main_menu(load_level)
end

function win()
	printh("You win")
	current_level_id += 1
	if current_level_id > #levels then
		current_level_id = 0
		show_main_menu()
	else
		load_level(current_level_id)
	end
end

function lose()
	load_level(current_level_id)
end

function player:get_gold(pos)
	sfx(GOLD_SOUND)
	level:get_gold(pos.x, pos.y)
end

function check_collisions()
	for e in all(enemies) do
		for e2 in all(enemies) do
			if e != e2 and aabb_sprite(e.position, e2.position) then
				printh("enemy collision")
				if e.collide != nil then
					e:collide(e2)
				end
			end
		end
		if aabb_sprite(e.position, player.position) then
			printh("player collision")
			if e.collide != nil then
				e:collide(player)
			end
			player:collide(e)
		end
	end
end

function _update()
	frame += 1
	local paused = gui:handle_input() or not running
	if level_loaded and not paused then
		player:update()
		if not player.has_moved then
			return
		end
		for e in all(enemies) do
			e:update()
		end
		level:update()
		check_collisions()
		if level.gold == 0 and round(player.position.y / 8) == level.mapY then
			win()
		end
	end
end

function set_palette(index)
	poke(0x5f2e, 1)
	pal(palettes[index], 1)
end

function _draw()
	cls()
	if level_loaded then
		-- Background
		palt(15, false)
		draw_shimmer(frame, level.mapX * 8, level.mapY * 8)
		palt(15, true)
		palt(0, false)
		level:draw()
		player:draw()
		for e in all(enemies) do
			e:draw()
		end
		effects:draw(level.mapX * 8, level.mapY * 8)
	end
	gui:draw()
	debug.draw()
end
__gfx__
000000001f5555ff1f5555ff1f5555ff1f5555ff1f5555ff1f5555f11f5555f1ffffffffffffffff1f5555f1ff5555ffffff5fff000000000000000000000000
000000001555555f1555555f1555555f1555555f1555555ff155551ff155551ff0011f5f00ff115ff504405fff04405fff0f40ff000000000000000000000000
00100100f15404fff15404fff15404fff15404fff15404fff155551ff155551ff006445500f66455f504405ff504f05fff04ff5f000000000000000000000000
00011000554444ff5544441f554444ff554444ff554444ff1f5555ffff5555fff7764055777640551f4444f11f4004f1fffffff1000000000000000000000000
00011000f666666f1166661fff666ffff1666ffff666666ff666666f16666661f7664455f7664455f666666ff66006fff6ff06ff000000000000000000000000
00100100f166661f1166700ff1166fff00116ffff1666661f07666f1ff6666fff6664555f66645550f6666f00f66f6f00f6fffff000000000000000000000000
00000000f177771ff077700ff1177fff071170fff17777ff000777ffff7777ffff66515ffff6515f00777700f0f777fff0ff7fff000000000000000000000000
00000000ff0000fff00fffffff000fffffff000fff0000fffffff00fff0000ffffff5f11ffff5f11ffffffffffffffffffffffff000000000000000000000000
00000000cccccccccccccccc00000000fcffffcff0ffff0fffffffff00000000ffffffff0000000000000000ffffffffff55ffff000000000000000000000000
00000000cbbbbbb0bbbbbfbb00000000fccccccff000000fcccccccc00000000ffffffff0000000000990aa0f555555ff5665fff000000000000000000000000
00000000cbbbbbb0bbbbbfbb00000000fcffffcff0ffff0fffffffff00000000ffffffff000550000999aa00f566665f56ff65ff000000000000000000000000
00000000cbbbbbb0bbbbbfbb00000000fcffffcff0ffff0fffffffff00000000ffffffff0055050009a99a00f566665f56ff655f000000000000000000000000
00000000cbbbbbb0cccccccc00000000fcffffcff0ffff0fffffffff00000000ff32212f0050005009aa9900f566665ff5666565000000000000000000000000
00000000cbbbbbb0bfbbbbbb00000000fccccccff000000fffffffff00000000ff33333f0000500500999900f566655fff55665f000000000000000000000000
00000000cbbbbbb0bfbbbbbb00000000fcffffcff0ffff0fffffffff00000000321232120000555500000000f566665fffff5665000000000000000000000000
0000000000000000bfbbbbbb00000000fcffffcff0ffff0fffffffff00000000333333330000000000000000f566665ffffff55f000000000000000000000000
ccccccccffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff66666666ffffffff66666666
bbbbbcbb6ff6fff6ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6ffffff6ffffffff6ffffff6
bbbbbcbbb66b666b6ffffff6ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6ffffff6ffffffff6ffffff6
bbbbbcbbbbbbbcbbb6ffff6bffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff6fffffff6fffffffffff6ffffff6ffffffff6ffffff6
ccccccccccccccccccffffcc6fffffffffffffffffffffffffffffffffffffffffffffffffff6fffffff6fffffffffffffffffff6ffffff6ffffffff6ffffff6
bcbbbbbbbcbbbbbbbc6666bbb6fffff6ffffffffffffffffffffffffffffffffffffffffffff6fffffffffffffffffffffffffff6ffffff6ffffffff6ffffff6
bcbbbbbbbcbbbbbbbcbbbbbbbc66f66b6ffffff6ffffffffffffffffffffffffffff6fffffffffffffffffffffffffffffffffff6ffffff6ffffffff6ffffff6
bcbbbbbbbcbbbbbbbcbbbbbbbcbb6bbbb666666bffffffff66fffff6f666666fffff6fffffffffffffffffffffffffffffffffff66666666ffffffff66666666
00000000ffaa99ffffaa99ffffaa99ffffaa99ffffaa99ffff999affff999affffffffffffffffffff99aaffff9999ffffff9fff000000000000000000000000
00000000fa99999ffa99999ffa99999ffa99999ffa99999ff99999aff99999aff0011f9f00ff119ff99999afff99999fff9f89ff000000000000000000000000
00000000fa9981fffa9981fffa9981fffa9981fffa9981fff99999aff99999aff00a889900faa899f918819ff918f19fff18ff9f000000000000000000000000
00000000f99988fff999881ff99988fff99988fff99988fff999999ff999999ff99a8199999a8199198888911f8888f1fffffff1000000000000000000000000
00000000faaaaaaf11aaaa1fffaaaffff1aaaffffaaaaaaffaaaaaaf1aaaaaa1f9aa999af9aa999afaaaaaaffaaaaafffaff0aff000000000000000000000000
00000000f1aaaa1f11aa900ff11aafff0011affff1aaaaa1f09aaaf1ffaaaafffaaa999afaaa999affaaaaff0faafaf00fafffff000000000000000000000000
00000000f199991ff099900ff1199fff091190fff19999ff000999ffff9999ffffaa9aaffffa9aaf00999900f0f999fff0ff9fff000000000000000000000000
00000000ff0000fff00fffffff000fffffff000fff0000fffffff00fff0000ffffffffffffffffff00ffff00ffffffffffffffff000000000000000000000000
ededededededededdedededeeeeeeeeeededededededededdedededeeeeeeeeeededededeeeeeeeededededefeeeeefeededededededededdedededefeeeeefe
dddddddddedededeeeeeeeeeeeeeeeeedddddddddedededeeeeeeeeeeeeeeeeeddddddddddddddddeeeeeeeeefeeefeedddddddddedededeeeeeeeeeefeeefee
ededddedededededdedededeeeeeeeeeededddedededededdedededeeeeeeeeeededddedeeeeeeeededededeeefefeeeededddedededededdedededeeefefeee
dddddddddedededeedeeedeeeeeeeeeedddddddddedededeedeeedeeeeeeeeeeddddddddddddddddedefedeeeeefeeeedddddddddedededeedeeedeeeeefeeee
ddedededededededdedededeeeeeeeeeddedededededededdedededeeeeeeeeefdedededeeeeeeeededededeeefefeeeddedededededededdedededeeefefeee
dddddddddddedddeeeeeeeeeeeeeeeeedddddddddddedddeeeeeeeeeeeeeeeeedddddddddddedddeeeeeeeeeefeeefeedddddddddddedddeeeeeeeeeefeeefee
ededededededededdedededeeeeeeeeeededededededededdedededeeeeeeeeeededededeeeeeeeededededefeeeeefeededededededededdedededefeeeeefe
dddddddddedededeeeeeeeeeeeeeeeeedddddddddedededeeeeeeeeeeeeeeeeedddddddddedddeddeeeeeeeeeeeeeeeedddddddddedededeeeeeeeeeeeeeeeee
ddddededededededededededeeeeeeeeddddededededededededededeeeeeeeeddddededfdedededededededeeeeeeeeddddededededededededededfeeeeefe
dddddddddedddedddeeedeeeeeeeeeeedddddddddedddedddeeedeeeeeeeeeeedddddddddedddedddefedeeeeeeeeeeedddddddddedddedddeeedeeeefeeefee
ededededededededededededeeeeeeeeededededededededededededeeeeeeeeededededededededededededeeeefeeeededededededededededededeefefeee
dddddddddedededeeedeeedeeeeeeeeedddddddddedededeeedeeedeeeeeeeeedddddddddedededeeedeeedeeeeefeeedddddddddedededeeedeeedeeeefeeee
edddedddededededededededeeeeeeeeedddedddededededededededeeeeeeeeedfdedddededededededededeefffffeedddedddededededededededeefefeee
dddddddddddedddedeeedeeeeeeeeeeedddddddddddedddedeeedeeeeeeeeeeedddddddddddedfdedeeedeeeeeeefeeedddddddddddedddedeeedeeeefeeefee
ddedddedededededededededeeeeeeeeddedddedededededededededeeeeeeeeddedddedededededededededeeeefeeeddedddedededededededededfeeeeefe
dddddddddedededeeedeeedeeeeeeeeedddddddddedededeeedeeedeeeeeeeeedddddddddedededeeedefedeeeeeeeeedddddddddedededeeedeeedeeeeeeeee
edddddddededededededededeeeeeeeeedddddddededededededededeeeeeeeeedddddddededededededededeeeeeeeeedddddddededededededededeeeeeeee
dddddddddedddedddedededeedeeedeedddddddddedddedddedededeedeeedeedddddddddedddedddedededeedeeedeedddddddddedddedddedededeedeeedee
ddddddddededededeeedeeedeeeeeeeeddddddddededededeeedeeedeeeeeeeeddddddddededededeeedeeedeeeeeeeeddddddddededededeeedeeedeeeeeeee
dddddddddddedddededededeeeedeeeddddddddddddedddededededeeeedeeeddfdddddddddedfdededededeeeedeeeddddddddddddedddededededeeeedeeed
ddddedddededededededededeeeeeeeeddddedddededededededededeeeeeeeeddddedddededededededededeeeeeeeeddddedddededededededededeeeeeeee
dddddddddedddedddedededeededededdddddddddedddedddedededeededededdddddddddedddedddedededeededededdddddddddedddedddedededeedededed
ddddddddedededededeeedeeeeeeeeeeddddddddedededededeeedeeeeeeeeeeddddddddedededededefedeeeeeeeeeeddddddddedededededeeedeeeeeeeeee
dddddddddddedddededededeededeeeedddddddddddedddededededeededeeeedddddddddddedddededededeededefeedddddddddddedddededededeededeeee
edddddddededededededededeeeeeeeeedddddddededededededededeeeeeeeeedddddddededededededededeeeeeeeeedddddddededededededededeeeeeeee
dddddddddddddddddedededeededededdddddddddddddddddedededeededededdddddddddddddfdddedededeededededdddddddddddddddddedededeedededed
ddddddddededededeeedeeedeeeeeeeeddddddddededededeeedeeedeeeeeeeeddddddddededededeeedefedeeeeeeeeddddddddededededeeedeeedeeeeeeee
dddddddddedddedddedededeedededeedddddddddedddedddedededeedededeedddddddddedddedddedededeedededefdddddddddedddedddedededeedededee
ddddddddededededededededeeeeeeeeddddddddededededededededeeeeeeeeddddddddededededededededeeeeeeeeddddddddededededededededeeeeeeee
dddddddddddddddddedededeedeeededdddddddddddddddddedededeedeeededdfdddddddddddddddedededeedeeededdddddddddddddddddedededeedeeeded
ddddddddededededededededeeeeeeeeddddddddededededededededeeeeeeeeddddddddededededededededeeeeeeeeddddddddededededededededeeeeeeee
dddddddddddddddddedededeededededdddddddddddddddddedededeededededdddddddddddddddddedededeededededdddddddddddddddddedededeedededed
11111111111111111111111111111111000000000000000000000000000000001100000000000000000000000000001100000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000004151000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11110000810000810000008100b11111000000000000004141000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11114102111111111111111111021111000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11114100000081000000008100001111000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11110202111111111111111102411111000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11110000000000000000000000411111000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11114102111111111111111102021111000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11114100000081000000810013001111000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11110202111111111111111102411111000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11110000000081000081000000411111000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11114102111111111111111102021111000000000000000041616161610000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11114100000081008113008100001111000000000000000041000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11110202111111111111111102021111000000000000000041000011131100000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000100041008111131100000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003434343434343434b434343434343434
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003535353535353535b535353535353535
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003636363636363636b636363636363636
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003737373737373737b737373737373737
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002424242424242424a424242424242424
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002525252525252525a525252525252525
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002626262626262626a626262626262626
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002727272727272727a727272727272727
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014141414141414149414141414141414
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015151515151515159515151515151515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016161616161616169616161616161616
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000017171717171717179717171717171717
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004040404040404048404040404040404
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005050505050505058505050505050505
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006060606060606068606060606060606
02020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
02020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020207070707070707078707070707070707

__gff__
0000000000000000000000000000000000858500840084008400008484000080858282828280808080808080808080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1500000000000000000000000000000015000000000000000000000000000015000000000000000000000000000000150000000000000000000000000015000000000000000000000000000000000015000000000000000000000000000000150000000015000000000000000000000000000000000000000000000000150000
1500000000000000000000000000000014161616161616161616161616161614000000000000000000000000000000150000001814000000151515151500000000000000000016161616161616162015000000310000000000000000000000150031180015000000000000000000000000000000000000000000003100150000
1500000000000000000000000000310014000000000031000000000000000014000000000000000000000000000000150000181400000015000000000000000000180018010014000000000000002015202020202020140000001800001800151420202020000000180018000000000016161616161616161611201120112014
1416161616161616161616161616160014000000000020182000000000000014001800180018001800000018001800150018140000000000150000000000000020202020202014000000180018002015180000202020140014111111111111111400000000001420202020200000000018001800180018000011000000000014
1431000000000000000000000000000014000000182018201820180000000014001400140014001400000014161420200014180000000015001800180031001400181800000014000000000000002015202020202020202014140000000000001400000000001400000000000000000016161600161616000011142011201120
2020140000000018000000002018202014000018201820182018201800000014001400140014001414001414001420180000140001001800202020202020140020202012202020201400000000002015000000000000000000140000000000002020201400001400000000001800180000180018001800180011140000000000
1820140000002020200000201820201814000020182018201820182000000014140000140014001400140014001420202020001420202020000018000000001400001800180018001400000000002015001800180000001800201416161600000000001400181400310000142020200000161616001616160011201120112014
2020140000000000000020202020202014002018201820182018201820000014001400140014001400140014001420180000140000180031180020201800140020202012202020202020140000002015202020202020202020201400000000000000001420202020200000140000000018001800180018000011000000000014
1820140001000000180000000000000014001820182018201820182018000014001400311400001400140014001420202014000000111111110018202000001418003118001800000000140000312015180018002000000000001400180018000000001400000000000000140018180016161600161616000011142011201120
2020202020201400202000180018001814002018201820182018201820000014112011201111140000180018001831182014001800180000000020201800140020202020202000202020201420202015202020142000000000001400000000000000001400001800000020202020201400180018001800180011140000000000
2018180000201400000020112011201114000020182018201820182000000014000014000000140000202020202020202020202020201420200018202000001400000000002000200000001400000015001831140018200000001400202020200000001420202020000000000000001420112011201120111211201120112014
2020202014201400000000001800180014000000201820182018200000000014000014202000140014141414001414142020202020142014200020201800140014111111142000200000001400001815142020202020200014201401200000001420202020000000000000002000001400000000000000000000000031000014
2020202014201400000000202020202014000000002018201820000000000014142000200000140014181414001414002020202020142014200018202000001414111800142000200014201420202020140000000000200014201420201420201400180018000000000000312014200014201120112011201120112011201120
2020202014202014000000202018182014000000000020182000000000000014002014200000140014141400140014142020202020142014200020201800140014111111111100200014201420142018202020202014200014201420001420181420202020202020202020202000201414000000000000000000000000000000
2018181814182014000000002020202014010000000000200000000031000014142018200000141401000018000014182020181820001814200000000000001414180018001831000014201420142000001800310014000014201420001420001400000000180000180001002014201820112011201120112011201120112014
2020202020202020202020202020202020202020202020202020202020202020202020202020202014202020202020202020202020202020112011201120112020202020202020202020202020202020202020202020202020202020202020202011201120112011201120112020202000310000000100000000000000000014
0000000000000000000000000000150000000000000000000000000000000015000000000000000000000000000000150000000000000000000000000000001500000000000000000000000000000000000000000000000000000000000000000000000000000000310000000000001500000000001500000000150000000000
0000000000000000000000000000150000000000000000000000000000000015000000000000000000000018001800150000183100180000000000000000001520202020202014000000000000000000150000000000000000000000000000150116161616161616161616000000001500000000001500000000150000000000
0000001800001800001800001801150000000018001800001800311831311115000000000000002020202020202020141420202020202020202000000000001501000018161620202020140000000000141616161616161616161616161616141400000000001100180000003115201500000000001500000000150000000000
14202020202020202020202020202000142020202020202020202020202020150000000000200000183100180018001414000000000000110000001800001815313131201516160000202020202020151400000000000000000000000000001414002018200020202020202020202015000000000015001b0031150000000000
1400001800001831001800001800001814001800000018001800001800000015000000000020202020202020202020141400000000001120202020202020202020202020150000181616000000000015141818180000000000000000000000141400002118200000000000000000001500000000001411201120140000000000
14202020202020202020202020141800202020202020202020202020202014150000142014000100180000180018001414161616161616161616161616161614000000201515152015001816160000151418000018181800181818000000181414002018201820000000000000000015000000000014001c0018140000000000
1400180000180000180000002014001800000018000000180000180000001415000014202020202020202020202020140000000000000000000000000000001400000020202020201515201500000015140000001800001800001800001800141400002018201820001800180014201500000000142011201120111400000000
1420202020202020202014182014180014202020202020202020202020202020000014201818002000180000180000140000180000180000180000000000001400000020000000202020201500181615140000001800001800001800001800141400000020182020202020202020201400000000140018001800181400000000
1400000000003100002014002014001814000000000000001800180000180000000014202020202020202020202020142020202020202020202020000000001400000020000000200000201515200015140000001800001800000018180000141400000000202020000000000000001400000014112011201120112014000000
2020142020202014182014182014180020202020202020202020202020202014000014201818180018003118001800140000000000000000000000183100181400000020000000200000202020201515140000000000000000000000000000142020202020202020152020202020201400000014003118001800180014000000
0000140000002014002014002014001800000000000000180018000000001814000014202020202020202020202020142000000100142000000014202020202000000020000000200000200000201514141616161616141414141616161616140000000000000000152018142000001400001420112011201120112011140000
1420181114002014182014182014180020000000142020202020202020202020000014200000181800200018180031142020202020142000000014000000000000000000000000000000000000001518140100000000000000000000003131141800000000002014152000002000001400001400000018000018003100140000
1820141114182014002014002014001820202020140001001800001800001800200014200020202020201420202020202020202020142020202020202014000000201411111111111111111111111520142020000000000000000000002020142020202020142020202011112020202000141120112011201120112011201400
1420181114002014182014182014180020142020201420202020122020202020202020201420181818001420202020202018000014202014000000000014000000201420202020202020202020201520142000142000180000180020140020140000000000140000000000000000002000140000180018001800180018001400
1820141114182014002014002014001820181420201400000000000000000000202018201420202020202020202020202000201420202014000018001800183118201420202020202020202020201520142000150014201818201400150020141800000000140000180014121400182014201120112011201120112011201114
2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202011111111111111111118201420202020202020202020202020142000151815180000181518150020142020202020202020202020202020202014000000180001180018001800000014
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
490c00001d56324503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503005030050300503
010400001d54324563005030050300503005030050300503115331855300503005030050300503005030050311523185430050300503005030050300503005031151318523005030050300503005030050300503
080300002841328433284132843328413284332841328433284132843324403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403004030040300403
791000002953535555355053550500500095002f50000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

