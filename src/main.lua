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

#include vector.lua
#include utilities.lua
#include aabb.lua
#include animator.lua
#include palettes.lua
#include character.lua
#include player.lua
#include enemy.lua
#include level.lua
#include gui/window_manager.lua
#include gui/renderer.lua
#include gui/lr_widgets.lua
#include effects.lua
#include noise.lua
#include background-shimmer.lua

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
end

function _init()
	set_palette(0)
	show_main_menu()
	-- 142 is the O key
	menuitem(1, "\142 digs left", swap_controls)
end

function swap_controls()
	swapped_controls = not swapped_controls
	menuitem(1, "\142 digs right", swap_controls)
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
end
