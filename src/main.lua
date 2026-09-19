-- settings
--[[$const]] SPEED = 1
--[[$const]] GRAVITY = SPEED
--[[$const]] ANIMATION_RATE = 4
-- brick lifecycle
--[[$const]] BRICK_END = 90
-- flags
--[[$const]] COLLISION_FLAG = 0
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

local player = Player:new()
local enemies = {}
local bricks = {}
local level = Level:new(0, 0)
frame = 0

function player:shoot(left)
	sfx(SHOOT_SOUND)
	if left then
		level:zap_block(get_floor_left(player:pos()))
	else
		level:zap_block(get_floor_right(player:pos()))
	end
end

function _init()
	set_palette()
	level:place_player(player)
	level:place_enemies(enemies)
	level:init()
end

function win()
	printh("You win")
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
	player:update()
	for e in all(enemies) do
		e:update()
	end
	level:update()
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
	-- Background
	palt(15, false)
	map(112, 048, 0, 0, 128, 128)
	palt(15, true)
	palt(0, false)
	level:draw()
	player:draw()
	for e in all(enemies) do
		e:draw()
	end
end
