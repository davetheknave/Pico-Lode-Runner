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

-- player states
--[[$const]] PLAYER_STANDING = 1
--[[$const]] PLAYER_WALKING = 2
--[[$const]] PLAYER_SHOOTING = 3
--[[$const]] PLAYER_CLIMBING = 4
--[[$const]] PLAYER_SHIMMYING = 5
--[[$const]] PLAYER_FALLING = 6
--[[$const]] PLAYER_DYING = 7

--player
local p1=
{
	x=71,
	y=16,
	state=0,
	facing_left=false,
	animation=PLAYER_STANDING,
	frame=0,
}

player_animations = {
	{2,3,4},
	{1},
	{5},
	{6,7},
	{8,9},
	{10},
	{10,11,12}
}

function p1:pos()
	return {x=self.x/8, y=self.y/8}
end

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
	set_palette()
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
	if player_tile == SHIMMY_TILE and p1.y % 8 == 0 then
		up_allowed = false
		p1.state = PLAYER_SHIMMYING
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
				if p1.state == PLAYER_SHIMMYING then
					p1.state = PLAYER_FALLING
				end
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

	-- animation
	frame += 1
	if frame % ANIMATION_RATE == 0 then
		p1.frame += 1
	end
end

function get_sprite(frame, animations, state)
	local loop = animations[state]
	return loop[frame % (#loop)+1]
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
	local sprite = get_sprite(p1.frame, player_animations, p1.state)
	spr(sprite,p1.x,p1.y,1,1,p1.facing_left)
end
