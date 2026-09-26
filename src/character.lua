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

Character.animations = {
	[STATE_STANDING] = make_animation({
		frames = { { sprite = 0 } }
	}),
	[STATE_WALKING] = make_animation({
		frames = { { sprite = 1 }, { sprite = 2, bounce = 1 }, { sprite = 3, bounce = 0 }, { sprite = 2, bounce = 1 } }
	}),
	[STATE_SHOOTING] = make_animation({
		frames = { { sprite = 4 } }
	}),
	[STATE_CLIMBING] = make_animation({
		frames = { { sprite = 6 }, { sprite = 5 }, { sprite = 6 }, { sprite = 5, flip = true } }
	}),
	[STATE_SHIMMYING] = make_animation({
		frames = { { sprite = 7 }, { sprite = 8 } }
	}),
	[STATE_FALLING] = make_animation({
		frames = { { sprite = 9 } }
	}),
	[STATE_DYING] = make_animation({
		frames = { { sprite = 9 }, { sprite = 10 }, { sprite = 11 } },
		oneshot = true
	})
}

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
	local grounded = self:check_grounded()
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

function Character:check_grounded()
	local floor = get_floor(self:pos())
	return flr(floor[2]) >= (level.mapY + 16) or fget(mget(unpack(floor)), COLLISION_FLAG)
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
	if self:check_grounded() then
		self.y = flr(self.y / 8) * 8
	end
end

function Character:collide(other)
end

function Character:change_state(new_state)
	self.state = new_state
	self.animations[self.state]:start()
end

function Character:update()
	self:check_mobility()
	self:get_input()
	self:update_movement()
end

function Character:draw()
	local current_animation = self.animations[self.state]
	current_animation:draw(self.sprite, self.x, self.y, self.facing_left)
end
