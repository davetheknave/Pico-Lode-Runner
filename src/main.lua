--[[$const]] player_start_tile = 25
--[[$const]] enemy_spawn_tile = 26
--[[$const]] collision_flag = 0
--[[$const]] speed = 1

--player
p1=
{
	x=71,
	y=16,
	dx=0,
	dy=0,
	isgrounded=false,
	flipped=false
}
gravity=1

function place_player()
	for y=1,127 do
		for x=1,127 do
			local maptile = mget(x,y)
			if maptile == player_start_tile then
				p1.x = x * 8
				p1.y = y * 8
				return
			end
		end
	end
end

function _init()
	place_player()
end

function collide_map(sprite)
	local colliding = false
	local x1 = sprite.x/8
	local y1 = sprite.y/8
	local x2 = (sprite.x+7)/8
	local y2 = (sprite.y+7)/8
	local a = fget(mget(x1,y1),collision_flag)
	local b = fget(mget(x1,y2),collision_flag)
	local c = fget(mget(x2,y1),collision_flag)
	local d = fget(mget(x2,y2),collision_flag)
	return a or b or c or d
end

function touching_floor(sprite)
	-- sprite could be overlapping as many as four tiles. We need to get all of them.
	local x1 = sprite.x/8 -- leftish x
	local x2 = (sprite.x+7)/8 -- rightish x
	local y1 = sprite.y/8 -- uppish y
	local y2 = (sprite.y+7)/8 -- downish y
	local a = fget(mget(x1,y1),collision_flag)
	local b = fget(mget(x1,y2),collision_flag)
	local c = fget(mget(x2,y1),collision_flag)
	local d = fget(mget(x2,y2),collision_flag)
	return a or b or c or d
end

function _update()
	local startx = p1.x

	-- gravity
	p1.dy=gravity
	p1.y+=p1.dy
	local ground=mget((p1.x)/8,(p1.y+8)/8)
	local ground2=mget((p1.x+7)/8,(p1.y+8)/8)
	p1.isgrounded=false
	if p1.dy>=0 then
		if fget(ground,collision_flag) or fget(ground2,collision_flag) then
			p1.y = flr((p1.y)/8)*8
			p1.dy = 0
			p1.isgrounded=true
		end
	end

	-- player input
	p1.dx = 0
	if btn(0) and p1.isgrounded then --left
		p1.flipped = true
		p1.dx = -speed
	end
	if btn(1) and p1.isgrounded then --right
		p1.dx = speed
		p1.flipped = false
	end

	-- collision
	p1.x+=p1.dx
	local xoffset=0
	if p1.dx>0 then xoffset=7 end
	local next_tile=mget((p1.x+xoffset)/8,(p1.y+7)/8)
	if fget(next_tile,collision_flag) then
		p1.x = startx
	end
end

function _draw()
	cls()
	map(0,0,0,0,128,128,128)
	spr(1,p1.x,p1.y,1,1,p1.flipped)
end

