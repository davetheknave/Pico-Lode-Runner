-- settings
--[[$const]] SPEED = 1
--[[$const]] GRAVITY = SPEED
--[[$const]] ANIMATION_RATE = 4
-- tiles/sprites
--[[$const]] GOLD_TILE = 24
--[[$const]] PLAYER_START_TILE = 25
--[[$const]] ENEMY_SPAWN_TILE = 26
--[[$const]] LADDER_TILE = 20
--[[$const]] SHIMMY_TILE = 22
-- flags
--[[$const]] COLLISION_FLAG = 0
-- sounds
--[[$const]] GOLD_SOUND = 63

#include utilities.lua
#include character.lua
#include player.lua
#include enemy.lua

local player = Player:new()
local enemies = {}

function round(value)
	return value >= 0 and flr(value + 0.5) or ceil(value - 0.5)
end

gold = 0
frame = 0

function place_player()
	for y=1,127 do
		for x=1,127 do
			local maptile = mget(x,y)
			if maptile == PLAYER_START_TILE then
				player:move_to(x*8, y*8)
				return
			end
		end
	end
end

function place_enemies()
	for y=1,127 do
		for x=1,127 do
			local maptile = mget(x,y)
			if maptile == ENEMY_SPAWN_TILE then
				local enemy = Enemy:new()
				enemy:move_to(x*8,y*8)
				enemies[#enemies+1] = enemy
				return
			end
		end
	end
end



function count_remaining_gold()
	for y=1,127 do
		for x=1,127 do
			if mget(x,y) == GOLD_TILE then
				gold += 1
			end
		end
	end
end

function _init()
	place_player()
	place_enemies()
	count_remaining_gold()
	set_palette()
end


function win()
	printh("You win")
end

function get_gold(pos)
	sfx(GOLD_SOUND)
	mset(round(pos.x),round(pos.y),0)
	gold -= 1
	if gold <= 0 then
		win()
	end
end

function _update()
	frame += 1
	player:update()
	for e in all(enemies) do
		e:update()
	end

end

function set_palette()
	poke(0x5f2e, 1)
	pal({[0]=
	-16,7,10,9,		-- Black, white, gold, gold-shade
	15,2,14,9,		-- Skin, Helmet, Shirt, Pants
	6,-11,-10,			-- RSkin, RHelmet, RShirt
	-12, -10,		-- brick1, brick2
	-- -13, 3,		-- brick1, brick2
	-15,-14,1		-- bg1, bg2, bg3
},1)
end

function _draw()
	cls()
	palt(15,false)
	map(112,048,0,0,128,128)
	palt(15,true)
	palt(0, false)
	map(0,0,0,0,128,128,128)
	player:draw()
	for e in all(enemies) do
		e:draw()
	end
end
