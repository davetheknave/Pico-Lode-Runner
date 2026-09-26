pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
package={loaded={},_c={}}
package._c["utilities"]=function()
function get_tile(pos)
	return mget(
		round(pos.x),
		round(pos.y)
	)
end

function get_floor(pos)
	return {
		round(pos.x),
		pos.y + 1
	}
end

function get_floor_left(pos)
	return {
		round(pos.x) - 1,
		pos.y + 1
	}
end
function get_floor_right(pos)
	return {
		round(pos.x) + 1,
		pos.y + 1
	}
end

function get_ceiling(pos)
	return {
		round(pos.x),
		ceil(pos.y - 1)
	}
end

function get_left(pos)
	return {
		ceil(pos.x - 1),
		round(pos.y)
	}
end

function get_right(pos)
	return {
		pos.x + 1,
		round(pos.y)
	}
end

function round(value)
	return value >= 0 and flr(value + 0.5) or ceil(value - 0.5)
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
    return aabb(pos1.x * 8, pos1.y * 8, 8, 8, pos2.x * 8, pos2.y * 8, 8, 8)
end
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
-- Other constants
--[[$const]] SHOOT_DURATION = 0.5

local player_animations = {
	{ 1, 2, 3 },
	{ 0 },
	{ 4 },
	{ 5, 6 },
	{ 7, 8 },
	{ 9 },
	{ 9, 10, 11 }
}

Character = {
	x = 0,
	y = 0,
	dx = 0,
	dy = 0,
	state = STATE_STANDING,
	facing_left = false,
	animation = STATE_STANDING,
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

function Character:new()
	local instance = setmetatable({}, self)
	return instance
end

function Character:pos()
	return { x = self.x / 8, y = self.y / 8 }
end

function Character:move_to(x, y)
	self.x = x
	self.y = y
end

function Character:get_sprite()
	local loop = player_animations[self.state]
	return loop[self.frame % #loop + 1] + self.sprite
end

function Character:check_mobility()
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
	-- Get surroundings and determine what movement is possible
	local below = get_floor(self:pos())
	local floor = mget(unpack(below))
	local grounded = fget(floor, COLLISION_FLAG) or below[2] > level.mapY + 16
	local player_tile = get_tile(self:pos())
	local touching_ladder = player_tile == LADDER_TILE or floor == LADDER_TILE

	self.down_allowed = not grounded

	if floor == LADDER_TILE or grounded then
		self.state = STATE_STANDING
	else
		self.state = STATE_FALLING
	end

	self.up_allowed = false
	if touching_ladder then
		if not grounded then
			self.state = STATE_CLIMBING
		end
		if not ((self.y % 8 == 0) and not (player_tile == LADDER_TILE)) then
			self.up_allowed = true
		else
			self.state = STATE_STANDING
		end
	end
	local ceiling = get_ceiling(self:pos())
	if fget(mget(unpack(ceiling)), COLLISION_FLAG) or ceiling[2] < level.mapY then
		self.up_allowed = false
	end
	if player_tile == SHIMMY_TILE and self.y % 8 == 0 then
		self.up_allowed = false
		self.state = STATE_SHIMMYING
	end
	local left = get_left(self:pos())
	local right = get_right(self:pos())
	self.left_allowed = not fget(mget(unpack(left)), COLLISION_FLAG) and not (left[1] < level.mapX)
	self.right_allowed = not fget(mget(unpack(right)), COLLISION_FLAG) and not (right[1] > level.mapX + 16)

	local approx_left = mget(round(self:pos().x) - 1, round(self:pos().y))
	local approx_right = mget(round(self:pos().x) + 1, round(self:pos().y))
	self.shoot_left_allowed = mget(unpack(get_floor_left(self:pos()))) == BRICK_TILE and not fget(approx_left, BLOCK_ZAP_FLAG)
	self.shoot_right_allowed = mget(unpack(get_floor_right(self:pos()))) == BRICK_TILE and not fget(approx_right, BLOCK_ZAP_FLAG)
end

function Character:get_input()
	printh("This shouldn't run")
end

function Character:update_movement()
	-- the game nudges the player towards the center of the axis they are walking on
	if self.dx != 0 and self.dy != 0 then
		printh("Trying to move diagonally")
	else
		if self.dx != 0 or self.state == STATE_SHOOTING then
			if self.y % 8 >= 4 then
				self.dy = min(self.y % 8, SPEED)
			else
				self.dy = max(-(self.y % 8), -SPEED)
			end
		end
		if self.dy != 0 or self.state == STATE_FALLING or self.state == STATE_SHOOTING then
			if self.x % 8 >= 4 then
				self.dx = min(self.x % 8, SPEED)
			else
				self.dx = max(-(self.x % 8), -SPEED)
			end
		end
	end

	-- Resolve movement
	self.x += self.dx
	self.y += self.dy

	if self.state == STATE_FALLING then
		self.y += GRAVITY
	end
	local floor = get_floor(self:pos())
	local grounded = fget(mget(unpack(floor)), COLLISION_FLAG) or floor[2] > level.mapY + 16
	if grounded then
		self.y = flr(self.y / 8) * 8
	end
end

function Character:update_animation()
	if frame % ANIMATION_RATE == 0 then
		self.frame += 1
	end
end

function Character:collide(other)
end

function Character:update()
	self:check_mobility()
	self:get_input()
	self:update_movement()
	self:update_animation()
end

function Character:draw()
	local sprite = self:get_sprite()
	spr(sprite, self.x, self.y, 1, 1, self.facing_left)
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
				self.dx = -SPEED
			elseif self.right_allowed and btn(1) then
				--right
				self.dx = SPEED
				self.facing_left = false
			end
		end

		-- can't move vertical and horizontal. vertical has priority
		if not (btn(2) and btn(3)) then
			if self.up_allowed and btn(2) then
				-- up
				self.dx = 0
				self.dy = -SPEED
			elseif self.down_allowed and btn(3) then
				-- down
				self.dx = 0
				self.dy = SPEED
			end
		end

		if self.shoot_left_allowed and btn(4) then
			-- O
			self:shoot(true)
			self.facing_left = true
			self.state = STATE_SHOOTING
			self.last_state_change = time()
			self.dx = 0
			self.dy = 0
		end
		if self.shoot_right_allowed and btn(5) then
			-- X
			self:shoot(false)
			self.facing_left = false
			self.state = STATE_SHOOTING
			self.last_state_change = time()
			self.dx = 0
			self.dy = 0
		end
	end
end

function Player:collide(other)
	lose()
end

function Player:update()
	self:check_mobility()
	self:get_input()
	self:update_movement()
	-- game logic
	local next_tile = get_tile(self:pos())
	if next_tile == GOLD_TILE then
		self:get_gold(self:pos())
	end
	self:update_animation()
end

function Player:new()
	local instance = Character:new()
	setmetatable(instance, self)
	instance.sprite = 1
	return instance
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
    return instance
end

function Enemy:check_path_to_player()
    local myy = round(self.y / 8)
    for x = round(self.x / 8), round(player.x / 8), (self.x < player.x and 1 or -1) do
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
    if abs(player.y - self.y) <= 4 and self:check_path_to_player() then
        if self.x - player.x > 0 and self.left_allowed then
            self.dx = -SPEED
        elseif self.x - player.x < 0 and self.right_allowed then
            self.dx = SPEED
        end
    end
end
end
package._c["level"]=function()
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
function require(p)
local l=package.loaded
if (l[p]==nil) l[p]=package._c[p]()
if (l[p]==nil) l[p]=true
return l[p]
end
-- settings
--[[$const]] SPEED = 1
--[[$const]] GRAVITY = SPEED
--[[$const]] ANIMATION_RATE = 4
-- brick lifecycle
--[[$const]] BRICK_END = 90
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

require("utilities")
require("aabb")
require("character")
require("player")
require("enemy")
require("level")
require("gui/window_manager")
require("gui/renderer")
require("gui/lr_widgets")

player = Player:new()
local gui = GUI:new(0, 0)
frame = 0
running = false
current_level_id = 0

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
		level:zap_block(get_floor_left(player:pos()))
	else
		level:zap_block(get_floor_right(player:pos()))
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
	printh(#enemies)
	level:init()
	running = true
end

function _init()
	set_palette()
	show_main_menu()
end

function show_main_menu()
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
	local won = level:get_gold(round(pos.x), round(pos.y))
	if won then
		win()
	end
end

function check_collisions()
	for e in all(enemies) do
		for e2 in all(enemies) do
			if e != e2 and aabb_sprite(e:pos(), e2:pos()) then
				printh("enemy collision")
				if e.collide != nil then
					e.collide(e2)
				end
			end
		end
		if aabb_sprite(e:pos(), player:pos()) then
			printh("player collision")
			if e.collide != nil then
				e.collide(player)
			end
			player.collide(e)
		end
	end
end

function _update()
	frame += 1
	local paused = gui:handle_input()
	if running and not paused then
		player:update()
		for e in all(enemies) do
			e:update()
		end
		level:update()
		check_collisions()
	end
end

function set_palette()
	poke(0x5f2e, 1)
	pal(
		{
			[0] = -16, 7, 10, 9, -- Black, white, gold, gold-shade
			15, 2, 14, 9, -- Skin, Helmet, Shirt, Pants
			6, -11, -10, -- RSkin, RHelmet, RShirt
			-12, -10, -- brick1, brick2
			-- -13, 3,		-- brick1, brick2
			-15, -14, 1 -- bg1, bg2, bg3
		}, 1
	)
end

function _draw()
	cls()
	if running then
		-- Background
		palt(15, false)
		map(112, 048, level.mapX * 8, level.mapY * 8, 128, 128)
		palt(15, true)
		palt(0, false)
		level:draw()
		player:draw()
		for e in all(enemies) do
			e:draw()
		end
	end
	gui:draw()
end
__gfx__
000000001f5555ff1f5555ff1f5555ff1f5555ff1f5555ff1f5555f11f5555f1ffffffffffffffff1f5555f1ff5555ffffff5fff000000000000000000000000
000000001555555f1555555f1555555f1555555f1555555ff155551ff155551ff0011f5f00ff115ff504405fff04405fff0f40ff000000000000000000000000
00100100f15404fff15404fff15404fff15404fff15404fff155551ff155551ff006445500f66455f504405ff504f05fff04ff5f000000000000000000000000
00011000554444ff554444ff554444ff554444ff554444ff1f5555ffff5555fff7764055777640551f4444f11f4004f1fffffff1000000000000000000000000
00011000f666666f1166661fff666fffff666ffff666666ff666666f16666661f7664455f7664455f666666ff66006fff6ff06ff000000000000000000000000
00100100f166661f1166700ff1166fff00116ffff1666661f07666f1ff6666fff6664555f66645550f6666f00f66f6f00f6fffff000000000000000000000000
00000000f177771ff077700ff1177fff071170fff17777ff000777ffff7777ffff66515ffff6515f00777700f0f777fff0ff7fff000000000000000000000000
00000000ff0000fff00fffffff000fffffff000fff0000fffffff00fff0000ffffff5f11ffff5f11ffffffffffffffffffffffff000000000000000000000000
00000000cccccccccccccccc00000000fcffffcff0ffff0fffffffffffffffffffffffffffffffffffffffffffffffffff55ffff000000000000000000000000
00000000cbbbbbb0bbbbb0bb00000000fccccccff000000fcccccccc00000000fffffffff55fff55f99fff99f555555ff5665fff000000000000000000000000
00000000cbbbbbb0bbbbb0bb00000000fcffffcff0ffff0ffffffffffffffffffffffffff55fff55f99fff99f566665f56ff65ff000000000000000000000000
00000000cbbbbbb0bbbbb0bb00000000fcffffcff0ffff0ffffffffffffffffffffffffffffffffffffffffff566665f56ff655f000000000000000000660000
00000000cbbbbbb0cccccccc00000000fcffffcff0ffff0fffffffffffffffffff32212ffffffffffffffffff566665ff5666565000000000000000000600000
00000000cbbbbbb0b0bbbbbb00000000fccccccff000000fffffffffffffffffff33333ff5fffff5ff99999ff566655fff55665f000000000000000000666000
00000000cbbbbbb0b0bbbbbb00000000fcffffcff0ffff0fffffffffffffffff32123212ff5fff5ff9fffff9f566665fffff5665000000000000000000000600
0000000000000000b0bbbbbb00000000fcffffcff0ffff0fffffffffffffffff33333333fff555fff9fffff9f566665ffffff55f000000000000000000000000
00000000ccccccccffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbcbb6ff6fff6ffffffffffffffffffffffffffffffff000660000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbcbbb66b666b6ffffff6ffffffffffffffffffffffff000666000000000000000000000000000000000000000000000000000000000000000000
06660000bbbbbcbbbbbbbcbbb6ffff6bffffffffffffffffffffffff000606600000000000000000000000000000000000000000000000000000000000000000
00060000ccccccccccccccccccffffcc6fffffffffffffffffffffff006666600000000000000000000000000000000000000000000000000000000000000000
00006000bcbbbbbbbcbbbbbbbc6666bbb6fffff6ffffffffffffffff006066000000000000000000000000000000000000000000000000000000000000000000
00000000bcbbbbbbbcbbbbbbbcbbbbbbbc66f66b6ffffff6ffffffff000000000000000000000000000000000000000000000000000000000000000000000000
00000000bcbbbbbbbcbbbbbbbcbbbbbbbcbb6bbbb666666bfff6ffff000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffaa99ffffaa99ffffaa99ffffaa99ffffaa99ffff999affff999affffffffffffffffffff99aaffff9999ffffff9fff000000000000000000000000
00000000fa99999ffa99999ffa99999ffa99999ffa99999ff99999aff99999aff0011f9f00ff119ff99999afff99999fff9f89ff000000000000000000000000
00000000fa9981fffa9981fffa9981fffa9981fffa9981fff99999aff99999aff00a889900faa899f918819ff918f19fff18ff9f000000000000000000000000
00000000f99988fff99988fff99988fff99988fff99988fff999999ff999999ff99a8199999a8199198888911f8008f1fffffff1000000000000000000000000
00000000faaaaaaf11aaaa1fffaaafffffaaaffffaaaaaaffaaaaaaf1aaaaaa1f9aa999af9aa999afaaaaaaffaa00afffaff0aff000000000000000000000000
00000000f1aaaa1f11aa900ff11aafff0011affff1aaaaa1f09aaaf1ffaaaafffaaa999afaaa999affaaaaff0faafaf00fafffff000000000000000000000000
00000000f199991ff099900ff1199fff091190fff19999f1000999ffff9999ffffaa9aaffffa9aaf00999900f0f999fff0ff9fff000000000000000000000000
00000000ff0000fff00fffffff000fffffff000fff0000fffffff00fff0000ffffffffffffffffff00ffff00ffffffffffffffff000000000000000000000000
dddedddeeeeeeeeefefefefeffffffffdededede3e3e3e3ef3f3f3f3ffffffffdddedddeeeeeeeeefefefefeffffffff00000000000000000000000000000000
ededededeeeeeeeeefefefefffffffffedededede3e3e3e33f3f3f3fffffffffededededeeeeeeeeefefefefffffffff00000000000000000000000000000000
dedddeddeeeeeeeefefefefeffffffffdededede3e3e3e3ef3f3f3f3ffffffffdedddeddeeeeeeeefefefefeffffffff00000000000000000000000000000000
ededededeeeeeeeeefefefefffffffffededededeee3eee3333f333fffffffffededededeeeeeeeeefefefefffffffff00000000000000000000000000000000
dddedddeeeeeeeeefefefefeffffffffdededede3e3e3e3ef3f3f3f3ffffffffdddedddeeeeeeeeefefefefeffffffff00000000000000000000000000000000
ededededeeeeeeeeefefefefffffffffedededede3eee3ee3f333f33ffffffffededededeeeeeeeeefefefefffffffff00000000000000000000000000000000
dddddddddeeedeeefefefefeffffffffdedddedd3e3e3e3ef3f3f3f3ffffffffdddddddddeeedeeefefefefeffffffff00000000000000000000000000000000
ededededeeeeeeeeefefefefffffffffededededeee3eee3333f333fffffffffededededeeeeeeeeefefefefffffffff00000000000000000000000000000000
ddddddddeedeeedeeeefeeefffffffffdddedddeeeeeeeee33333333fffffff3ddddddddeedeeedeeeefeeefffffffff00000000000000000000000000000000
ededededeeeeeeeefefefefeffffffffedededede333e333f3f3f3f3ffffffffededededeeeeeeeefefefefeffffffff00000000000000000000000000000000
dddddddddeeedeeeefeeefeeffffffffdedddeddeeeeeeee33333333ffffffffdddddddddeeedeeeefeeefeeffffffff00000000000000000000000000000000
ededededeeeeeeeefefefefeffffffffedededed3e3e3e3ef3f3f3f3ffffffffededededeeeeeeeefefefefeffffffff00000000000000000000000000000000
dddddddddedededeeeefeeeffffefffedddedddeeeeeeeee33333333fff3ffffdddddddddedededeeeefeeeffffefffe00000000000000000000000000000000
edddedddeeeeeeeefefefefeffffffffededededeeeeeeee33333333ffffffffedddedddeeeeeeeefefefefeffffffff00000000000000000000000000000000
dddddddddedededeeeeeeeeefefffeffddddddddeeeeeeee33333333ffffffffdddddddddedededeeeeeeeeefefffeff00000000000000000000000000000000
ddedddedeeeeeeeefefefefeffffffffededededeeeeeeee33333333ffffffffddedddedeeeeeeeefefefefeffffffff00000000000000000000000000000000
ddddddddededededeeeeeeeefefffeffddddddddeeeeeeee33333333ffffffffddddddddededededeeeeeeeefefffeff00000000000000000000000000000000
ddedddedeeeeeeeeefefefefffffffffddedddedeeeeeeee33333333ffffffffddedddedeeeeeeeeefefefefffffffff00000000000000000000000000000000
ddddddddededededeeeeeeeefffefffedddddddddeeedeee33333333ff3fff3fddddddddededededeeeeeeeefffefffe00000000000000000000000000000000
edddeddddeeedeeeefefefefffffffffedddedddeeeeeeee33333333ffffffffedddeddddeeedeeeefefefefffffffff00000000000000000000000000000000
ddddddddededededeeeeeeeefefefefeddddddddeedeeede3e3e3e3ef3f3f3f3ddddddddededededeeeeeeeefefefefe00000000000000000000000000000000
ddddddddeedeeedeeeefeeefffffffffddddddddeeeeeeee33333333ffffffffddddddddeedeeedeeeefeeefffffffff00000000000000000000000000000000
ddddddddededededeeeeeeeefefefefeddddddddedededed3e3e3e3ef3f3f3f3ddddddddededededeeeeeeeefefefefe00000000000000000000000000000000
dddddddddeeedeeeefeeefeeffffffffddddddddeeeeeeee33333333ffffffffdddddddddeeedeeeefeeefeeffffffff00000000000000000000000000000000
eeeeeeeededededeeeeeeeeefefefefedddddddddededede3e3e3e3e3fff3fffdddddddddedededeeeeeeeeefefefefe00000000000000000000000000000000
eeeeeeeeededededeeefeeefffffffffddddddddedeeedeee3e3e3e3f3f3f3f3ddddddddededededeeefeeefffffffff00000000000000000000000000000000
eeeeffeededededeeeeeeeeefefefefedddddddddededede3e3e3e3eff3fff3fdddddddddedededeeeeeeeeefefefefe00000000000000000000000000000000
eeeeffeeededededeeeeeeeeefffefffddddddddeeedeeede3e3e3e3f3f3f3f3ddddddddededededeeeeeeeeefffefff00000000000000000000000000000000
eeeeeeeededededeeeeeeeeefefefefedddddddddededede3e3e3e3e3fff3fffdddddddddedededeeeeeeeeefefefefe00000000000000000000000000000000
eeeeeeeeededededeeeeeeeeffefffefddddddddedededede3e3e3e3f3f3f3f3ddddddddededededeeeeeeeeffefffef00000000000000000000000000000000
eeeeeeeededededeeeeeeeeefefefefedddddddddededede3e3e3e3e3f3f3f3fd0d0d0d0dedededeeeeeeeeefefefefe00000000000000000000000000000000
eeeeeeeeededededeeeeeeeeefffefffddddddddedededede3e3e3e3f3f3f3f30d0d0d0dededededeeeeeeeeefffefff00000000000000000000000000000000
11111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11110000810000810000008100b11111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11114112111111111111111111121111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11114100000081000000008100001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111212111111111111111112411111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11110000000000000000000000411111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11114112111111111111111112121111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111141000000810000008100a1001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111212111111111111111112411111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11110000000081000081000000411111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11114112111111111111111112121111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111141000000810081a1008100001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111212111111111111111112121111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000910000008100000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212
12121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000034343434343434343434343434343434
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000035353535353535353535353535353535
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000036363636363636363636363636363636
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000037373737373737373737373737373737
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000024242424242424242424242424242424
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000025252525252525252525252525252525
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000026262626262626262626262626262626
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000027272727272727272727272727272727
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014141414141414141414141414141414
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015151515151515151515151515151515
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000016161616161616161616161616161616
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000017171717171717171717171717171717
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004040404040404040404040404040404
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005050505050505050505050505050505
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006060606060606060606060606060606
12121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212
12121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121207070707070707070707070707070707

__gff__
0000000000000000000000000000000000858500840084008400008484000080808582828282828080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1500000000000000000000000000000015000000000000000000000000000015000000000000000000000000000000150000000000000000000000000015000000000000000000000000000000000015000000000000000000000000000000150000000015000000000000000000000000000000000000000000000000150000
15000000000000000000000000000000141616161616161616161616161616140000000000000000000000000000001500000018140000001515151515000000000000000000161616161616161621150000001a000000000000000000000015001a180015000000000000000000000000000000000000000000001a00150000
150000000000000000000000000000001400000000001a000000000000000014000000000000000000000000000000150000181400000015000000000000000000180018190014000000000000002115212121212121140000001800001800151421212121000000180018000000000016161616161616161611211121112114
1416161616161616161616161616160014000000000021182100000000000014001800180018001800000018001800150018140000000000150000000000000021212121212114000000180018002115180000212121140014111111111111111400000000001421212121210000000018001800180018000011000000000014
141a0000000000000000000000001a001400000018211821182118000000001400140014001400140000001416142121001418000000001500180018001a001400181800000014000000000000002115212121212121212114140000000000001400000000001400000000000000000016161600161616000011142111211121
2121140000000018000000002118212114000018211821182118211800000014001400140014001414001414001421180000140019001800212121212121140021212112212121211400000000002115000000000000000000140000000000002121211400001400000000001800180000180018001800180011140000000000
18211400000021212100002118212118140000211821182118211821000000141400001400140014001400140014212121210014212121210000180000000014000018001800180014000000000021150018001800000018002114161616000000000014001814001a0000142121210000161616001616160011211121112114
212114000000000000002121212121211400211821182118211821182100001400140014001400140014001400142118000014000018001a180021211800140021212112212121212121140000002115212121212121212121211400000000000000001421212121210000140000000018001800180018000011000000000014
18211400190000001800000000000000140018211821182118211821180000140014001a1400001400140014001421212114000000111111110018212100001418001a180018000000001400001a2115180018002100000000001400180018000000001400000000000000140018180016161600161616000011142111211121
212121212121140021210018001800181400211821182118211821182100001411211121111114000018001800181a182114001800180000000021211800140021212121212100212121211421212115212121142100000000001400000000000000001400001800000021212121211400180018001800180011140000000000
211818000021140000002111211121111400002118211821182118210000001400001400000014000021212121212121212121212121142121001821210000140000000000210021000000140000001500181a140018210000001400212121210000001421212121000000000000001421112111211121111211211121112114
212121211421140000000000180018001400000021182118211821000000001400001421210014001414141400141414212121212114211421002121180014001411111114210021000000140000181514212121212121001421141921000000142121212100000000000000210000140000000000000000000000001a000014
21212121142114000000002121212121140000000021182118210000000000141421002100001400141814140014140021212121211421142100182121000014141118001421002100142114212121211400000000002100142114212114212114001800180000000000001a2114210014211121112111211121112111211121
2121212114212114000000212118182114000000000021182100000000000014002114210000140014141400140014142121212121142114210021211800140014111111111100210014211421142118212121212114210014211421001421181421212121212121212121212100211414000000000000000000000000000000
211818181418211400000000212121211419000000000021000000001a00001414211821000014141900001800001418212118182100181421000000000000141418001800181a0000142114211421000018001a0014000014211421001421001400000000180000180019002114211821112111211121112111211121112114
21212121212121212121212121212121212121212121212121212121212121212121212121212121142121212121212121212121212121211121112111211121212121212121212121212121212121212121212121212121212121212121212121112111211121112111211121212121001a0000001900000000000000000014
00000000000000000000000000001500000000000000000000000000000000150000000000000000000000000000001500000000000000000000000000000015000000000000000000000000000000000000000000000000000000000000000000000000000000001a0000000000001500000000001500000000150000000000
0000000000000000000000000000150000000000000000000000000000000015000000000000000000000018001800150000181a00180000000000000000001521212121212114000000000000000000150000000000000000000000000000151916161616161616161616000000001500000000001500000000150000000000
00000018000018000018000018191500000000180018000018001a181a1a1115000000000000002121212121212121141421212121212121212100000000001519000018161621212121140000000000141616161616161616161616161616141400000000001100180000001a15211500000000001500000000150000000000
14212121212121212121212121212100142121212121212121212121212121150000000000210000181a001800180014140000000000001100000018000018151a1a1a211516160000212121212121151400000000000000000000000000001414002118210021212121212121212115000000000015001b001a150000000000
140000180000181a001800001800001814001800000018001800001800000015000000000021212121212121212121141400000000001121212121212121212121212121150000181616000000000015141818180000000000000000000000141400002118210000000000000000001500000000001411211121140000000000
14212121212121212121212121141800212121212121212121212121212114150000142114001900180000180018001414161616161616161616161616161614000000211515152115001816160000151418000018181800181818000000181414002118211821000000000000000015000000000014001c0018140000000000
1400180000180000180000002114001800000018000000180000180000001415000014212121212121212121212121140000000000000000000000000000001400000021212121211515211500000015140000001800001800001800001800141400002118211821001800180014211500000000142111211121111400000000
1421212121212121212114182114180014212121212121212121212121212121000014211818002100180000180000140000180000180000180000000000001400000021000000212121211500181615140000001800001800001800001800141400000021182121212121212121211400000000140018001800181400000000
1400000000001a00002114002114001814000000000000001800180000180000000014212121212121212121212121142121212121212121212121000000001400000021000000210000211515210015140000001800001800000018180000141400000000212121000000000000001400000014112111211121112114000000
2121142121212114182114182114180021212121212121212121212121212114000014211818180018001a18001800140000000000000000000000181a00181400000021000000210000212121211515140000000000000000000000000000142121212121212121152121212121211400000014001a18001800180014000000
0000140000002114002114002114001800000000000000180018000000001814000014212121212121212121212121142100001900142100000014212121212100000021000000210000210000211514141616161616141414141616161616140000000000000000152118142100001400001421112111211121112111140000
142118111400211418211418211418002100000014212121212121212121212100001421000018180021001818001a142121212121142100000014000000000000000000000000000000000000001518141900000000000000000000001a1a141800000000002114152100002100001400001400000018000018001a00140000
1821141114182114002114002114001821212121140019001800001800001800210014210021212121211421212121212121212121142121212121212114000000211411111111111111111111111521142121000000000000000000002121142121212121142121212111112121212100141121112111211121112111211400
1421181114002114182114182114180021142121211421212121122121212121212121211421181818001421212121212118000014212114000000000014000000211421212121212121212121211521142100142100180000180021140021140000000000140000000000000000002100140000180018001800180018001400
1821141114182114002114002114001821181421211400000000000000000000212118211421212121212121212121212100211421212114000018001800181a18211421212121212121212121211521142100150014211818211400150021141800000000140000180014121400182114211121112111211121112111211114
2121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212121212111111111111111111118211421212121212121212121212121142100151815180000181518150021142121212121212121212121212121212114000000180019180018001800000014
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

