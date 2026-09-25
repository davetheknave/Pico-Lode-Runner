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

#include utilities.lua
#include character.lua
#include player.lua
#include enemy.lua
#include level.lua
#include gui/window_manager.lua
#include gui/renderer.lua
#include gui/lr_widgets.lua

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
	current_level_id = levelID + 1
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
	running = true
end

function _init()
	set_palette()
	show_main_menu()
end

function show_main_menu()
	gui:make_level_select(load_level)
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

function _update()
	frame += 1
	local paused = gui:handle_input()
	if not paused then
		player:update()
		for e in all(enemies) do
			e:update()
		end
		level:update()
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
