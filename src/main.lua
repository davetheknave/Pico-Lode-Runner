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
local p1=
{
	x=71,
	y=16,
	state=0,
	facing_left=false,
}

function p1:pos()
	return {x=self.x/8, y=self.y/8}
end

function round(value)
	return value >= 0 and flr(value + 0.5) or ceil(value - 0.5)
end

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

function get_tile(pos)
	return mget(
		round(pos.x),
		round(pos.y)
	)
end

function get_floor(pos)
	return mget(
		round(pos.x),
		pos.y+1
	)
end

function get_ceiling(pos)
	return mget(
		round(pos.x),
		ceil(pos.y-1)
	)
end

function get_left(pos)
	return mget(
		ceil(pos.x-1),
		round(pos.y)
	)
end

function get_right(pos)
	return mget(
		pos.x+1,
		round(pos.y)
	)
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

function shoot()

end

function _update()
	-- Figure out player's surroundings
	local floor = get_floor(p1:pos())
	local grounded = fget(floor, COLLISION_FLAG)
	local player_tile = get_tile(p1:pos())
	local touching_ladder = player_tile == LADDER_TILE or floor == LADDER_TILE

	local down_allowed = not grounded
	
	if floor == LADDER_TILE or grounded then
		p1.state = PLAYER_STANDING
	else
		p1.state = PLAYER_FALLING
	end

	local up_allowed = false
	if touching_ladder then
		if not grounded then
			p1.state = PLAYER_CLIMBING
		end
		if not ((p1.y % 8 == 0) and not (player_tile == LADDER_TILE)) then
			up_allowed = true
		else
			p1.state = PLAYER_STANDING
		end
	end
	if fget(get_ceiling(p1:pos()),COLLISION_FLAG) then
		up_allowed = false
	end

	local left_allowed = not fget(get_left(p1:pos()),COLLISION_FLAG)
	local right_allowed = not fget(get_right(p1:pos()),COLLISION_FLAG)

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

	-- adjust movement
	-- the game nudges the player towards the center of the axis they are walking on
	if dx != 0 and dy != 0 then
		printh("Trying to move diagonally")
	elseif dx != 0 then
		if p1.y % 8 >= 4 then
			dy = min(p1.y % 8, SPEED)
		else
			dy = max(-(p1.y % 8), -SPEED)
		end
	elseif dy != 0 or p1.state == PLAYER_FALLING then
		if p1.x % 8 >= 4 then
			dx = min(p1.x % 8, SPEED)
		else
			dx = max(-(p1.x % 8), -SPEED)
		end
	end
	
	-- Resolve movement
	p1.x += dx
	p1.y += dy

	if p1.state == PLAYER_FALLING then
		p1.y+=GRAVITY
	end
	floor = get_floor(p1:pos())
	grounded = fget(floor, COLLISION_FLAG)
	if grounded then
		p1.y = flr((p1.y)/8)*8
	end

	-- game logic
	local next_tile = get_tile(p1:pos())
	if next_tile == GOLD_TILE then
		get_gold(p1:pos())
	end
end

function _draw()
	cls()
	map(0,0,0,0,128,128,128)
	spr(1,p1.x,p1.y,1,1,p1.facing_left)
end

