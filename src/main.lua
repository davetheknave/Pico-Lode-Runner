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
--[[$const]] PLAYER_STANDING = 0
--[[$const]] PLAYER_WALKING = 1
--[[$const]] PLAYER_CLIMBING = 2
--[[$const]] PLAYER_SHOOTING = 3
--[[$const]] PLAYER_SHIMMYING = 4
--[[$const]] PLAYER_FALLING = 5
--[[$const]] PLAYER_DYING = 6

--player
p1=
{
	x=71,
	y=16,
	state=0,
	facing_left=false,
	pos = function()
		return {x=x/8,y=y/8}
	end
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

-- function collide_map(sprite)
-- 	local colliding = false
-- 	local x1 = sprite.x/8 -- leftish x
-- 	local x2 = (sprite.x+7)/8 -- rightish x
-- 	local y1 = sprite.y/8 -- uppish y
-- 	local y2 = (sprite.y+7)/8 -- downish y
-- 	local a = fget(mget(x1,y1),COLLISION_FLAG)
-- 	local b = fget(mget(x1,y2),COLLISION_FLAG)
-- 	local c = fget(mget(x2,y1),COLLISION_FLAG)
-- 	local d = fget(mget(x2,y2),COLLISION_FLAG)
-- 	return a or b or c or d
-- end

-- function touching(sprite, thing_to_check)
-- 	-- sprite could be overlapping as many as four tiles. We need to get all of them.
-- 	local x_l = sprite.x/8 -- leftish x
-- 	local x_r = (sprite.x+7)/8 -- rightish x
-- 	local y_u = sprite.y/8 -- uppish y
-- 	local y_d = (sprite.y+7)/8 -- downish y
-- 	local a = mget(x_l,y_u) == thing_to_check
-- 	local b = mget(x_l,y_d) == thing_to_check
-- 	local c = mget(x_r,y_u) == thing_to_check
-- 	local d = mget(x_r,y_d) == thing_to_check
-- 	return a or b or c or d
-- end

function get_tile(x,y)
	local x = flr(x/8+0.5)
	local y = flr(y/8+0.5)
	return mget(x,y)
end


function near(sprite, thing_to_check)
	return get_tile(sprite.x,sprite.y) == thing_to_check
end

function near_flag(sprite, flag_to_check)
	return fget(get_tile(sprite.x,sprite.y),flag_to_check)
end

function get_floor(x,y)
	local x = flr((x/8)+0.5)
	local y = (y+8)/8
	return mget(x,y)
end

function get_ceiling(x,y)
	local x = flr((x/8)+0.5)
	local y = ceil((y-8)/8)
	return mget(x,y)
end

function get_left(x,y)
	local tile_x = ceil((x-8)/8)
	local tile_y = flr((y/8)+0.5)
	return mget(tile_x,tile_y)
end

function get_right(x,y)
	local tile_x = (x+8)/8
	local tile_y = flr((y/8)+0.5)
	return mget(tile_x,tile_y)
end

function near_under(sprite, thing_to_check)
	return get_floor(sprite.x,sprite.y) == thing_to_check
end

function near_under_flag(sprite,flag_to_check)
	return fget(get_floor(sprite.x,sprite.y), flag_to_check)
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

function shoot()

end

function _update()
	-- Gathering information
	touching_ladder = near(p1, LADDER_TILE) or near_under(p1, LADDER_TILE)

	-- Figure out player's surroundings
	local down_allowed = not near_under_flag(p1, COLLISION_FLAG)
	
	local grounded = false
	if near_under(p1, LADDER_TILE) or near_under_flag(p1, COLLISION_FLAG) then
		p1.state = PLAYER_STANDING
		grounded = true
	else
		p1.state = PLAYER_FALLING
	end

	local up_allowed = false
	if touching_ladder then
		if not near_under_flag(p1, COLLISION_FLAG) then
			p1.state = PLAYER_CLIMBING
		end
		if not ((p1.y % 8 == 0) and not near(p1, LADDER_TILE)) then
			up_allowed = true
		else
			p1.state = PLAYER_STANDING
		end
	end
	if fget(get_ceiling(p1.x,p1.y),COLLISION_FLAG) then
		up_allowed = false
	end

	local left_allowed = not fget(get_left(p1.x, p1.y),COLLISION_FLAG)
	local right_allowed = not fget(get_right(p1.x, p1.y),COLLISION_FLAG)

	-- Check Player input
	local dx = 0
	local dy = 0
	if p1.state != PLAYER_FALLING and p1.state != PLAYER_SHOOTING and p1.state != PLAYER_DYING then
		if not (btn(0) and btn(1)) then
			if left_allowed and btn(0) then -- left
				p1.facing_left = true
				dx = -SPEED
			elseif right_allowed and btn(1) then --right
				dx = SPEED
				p1.facing_left = false
			end
		end

		-- can't move vertical and horizontal. vertical has priority
		if not (btn(2) and btn(3)) then
			if up_allowed and btn(2) then -- up
				dx = 0
				dy = -SPEED
			elseif down_allowed and btn(3) then -- down
				dx = 0
				dy = SPEED
			end
		end

		if btn(4) then -- O
			shoot()
			dx = 0
			dy = 0
		end
		if btn(5) then -- X
			shoot()
			dx = 0
			dy = 0
		end
	end
	-- printh(p1.state)

	-- adjust movement
	-- the game nudges the player towards the center of the axis they are walking on

	
	-- Resolve movement
	local xoffset=0
	local yoffset=0
	if dx>0 then xoffset=7 end
	if dy>0 then yoffset=7 end
	local colliding_x = (p1.x+xoffset)/8
	local colliding_y = (p1.y+yoffset)/8
	local next_tile=mget(colliding_x,colliding_y)
	p1.x += dx

	if p1.state == PLAYER_FALLING then
		p1.y+=GRAVITY
	end
	if p1.state == PLAYER_STANDING then
		p1.y = flr((p1.y)/8)*8
	end
	if (up_allowed or down_allowed) then
		p1.y += dy
	end

	-- game logic
	if near(p1, GOLD_TILE) then
		get_gold(colliding_x,colliding_y)
	end
end

function _draw()
	cls()
	map(0,0,0,0,128,128,128)
	spr(1,p1.x,p1.y,1,1,p1.facing_left)
end

