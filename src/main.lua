-- settings
--[[$const]] SPEED = 1
--[[$const]] GRAVITY = SPEED
-- tiles/sprites
--[[$const]] GOLD_TILE = 24
--[[$const]] PLAYER_START_TILE = 25
--[[$const]] ENEMY_SPAWN_TILE = 26
--[[$const]] LADDER_TILE = 20
-- flags
--[[$const]] COLLISION_FLAG = 0
-- sounds
--[[$const]] GOLD_SOUND = 63

-- player states
--[[$const]] PLAYER_GROUNDED = 0
--[[$const]] PLAYER_FALLING = 1
--[[$const]] PLAYER_LADDERABLE = 2

--player
p1=
{
	x=71,
	y=16,
	state=0,
	facing_left=false
}
gold = 0

function place_player()
	for y=1,127 do
		for x=1,127 do
			local maptile = mget(x,y)
			if maptile == PLAYER_START_TILE then
				p1.x = x * 8
				p1.y = y * 8
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
	count_remaining_gold()
end

function collide_map(sprite)
	local colliding = false
	local x1 = sprite.x/8
	local y1 = sprite.y/8
	local x2 = (sprite.x+7)/8
	local y2 = (sprite.y+7)/8
	local a = fget(mget(x1,y1),COLLISION_FLAG)
	local b = fget(mget(x1,y2),COLLISION_FLAG)
	local c = fget(mget(x2,y1),COLLISION_FLAG)
	local d = fget(mget(x2,y2),COLLISION_FLAG)
	return a or b or c or d
end

function touching(sprite, thing_to_check)
	-- sprite could be overlapping as many as four tiles. We need to get all of them.
	local x1 = sprite.x/8 -- leftish x
	local x2 = (sprite.x+7)/8 -- rightish x
	local y1 = sprite.y/8 -- uppish y
	local y2 = (sprite.y+7)/8 -- downish y
	local a = mget(x1,y1) == thing_to_check
	local b = mget(x1,y2) == thing_to_check
	local c = mget(x2,y1) == thing_to_check
	local d = mget(x2,y2) == thing_to_check
	return a or b or c or d
end

function win()
	printh("You win")
end

function get_gold(x,y)
	sfx(GOLD_SOUND)
	mset(x,y,0)
	gold -= 1
	if gold <= 0 then
		win()
	end
end

function _update()
	-- Gathering information
	local groundLeftish=mget((p1.x)/8,(p1.y+8)/8)
	local groundRightish=mget((p1.x+7)/8,(p1.y+8)/8)
	local touching_ladder = touching(p1, LADDER_TILE) or groundLeftish == LADDER_TILE or groundRightish == LADDER_TILE

	-- Figure out the player's state
	if fget(groundLeftish,COLLISION_FLAG) or fget(groundRightish,COLLISION_FLAG) then
		p1.state = PLAYER_GROUNDED
	else
		p1.state = PLAYER_FALLING
	end
	if touching_ladder then
		p1.state = PLAYER_LADDERABLE
	end

	-- Check Player input
	local dx = 0
	local dy = 0
	if btn(0) and p1.state != PLAYER_FALLING then --left
		p1.facing_left = true
		dx = -SPEED
	end
	if btn(1) and p1.state != PLAYER_FALLING then --right
		dx = SPEED
		p1.facing_left = false
	end
	if btn(2) and p1.state == PLAYER_LADDERABLE then -- uprun
		dy = -SPEED
	end
	if btn(3) and p1.state == PLAYER_LADDERABLE then -- down
		dy = SPEED
	end
	if btn(4) and p1.state != PLAYER_FALLING then -- O

	end
	if btn(5) and p1.state != PLAYER_FALLING then -- X

	end
	printh(p1.state)
	
	-- Resolve movement
	local xoffset=0
	if dx>0 then xoffset=7 end
	local colliding_x = (p1.x+xoffset)/8
	local colliding_y = (p1.y+7)/8
	local next_tile=mget(colliding_x,colliding_y)
	if not fget(next_tile,COLLISION_FLAG) then
		p1.x += dx
	end

	if p1.state == PLAYER_FALLING then
		p1.y+=GRAVITY
	end
	if p1.state == PLAYER_GROUNDED then
		p1.y = flr((p1.y)/8)*8
	end
	if p1.state == PLAYER_LADDERABLE then
		p1.y += dy  -- TODO: don't let the player move through walls if on a ladder
	end

	-- game logic
	if next_tile == GOLD_TILE then
		get_gold(colliding_x,colliding_y)
	end
end

function _draw()
	cls()
	map(0,0,0,0,128,128,128)
	spr(1,p1.x,p1.y,1,1,p1.facing_left)
end

