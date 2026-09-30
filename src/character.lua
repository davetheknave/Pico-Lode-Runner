-- character states
--[[$const]] STATE_STANDING = 1
--[[$const]] STATE_WALKING = 2
--[[$const]] STATE_SHOOTING = 3
--[[$const]] STATE_CLIMBING = 4
--[[$const]] STATE_SHIMMYING = 5
--[[$const]] STATE_FALLING = 6
--[[$const]] STATE_DYING = 7
--[[$const]] STATE_LADDER = 8
-- Other constants
--[[$const]] SHOOT_DURATION = 0.5

Character = {
	dx = 0,
	dy = 0,
	state = STATE_STANDING,
	facing_left = false,
	-- animation = STATE_STANDING,
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
		frames = {
			{ sprite = 1, bounce = -1 },
			{ sprite = 2, bounce = 0 },
			{ sprite = 3, bounce = -1 },
			{ sprite = 2, bounce = 0 }
		}
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
	}),
	[STATE_LADDER] = make_animation({
		frames = { { sprite = 6 } }
	})
}

function Character:new()
	local instance = setmetatable({}, self)
	instance.position = Vector:new()
	return instance
end

function Character:get_tile()
	return Vector:new(round(self.position.x / 8), round(self.position.y / 8))
end

function Character:get_floor()
	return Vector:new(round(self.position.x / 8), flr(self.position.y / 8 + 1))
end

function Character:get_ceiling()
	return Vector:new(round(self.position.x / 8), ceil(self.position.y / 8 - 1))
end

function Character:get_left()
	return Vector:new(ceil(self.position.x / 8 - 1), round(self.position.y / 8))
end

function Character:get_right()
	return Vector:new(flr(self.position.x / 8 + 1), round(self.position.y / 8))
end

function Character:get_floor_left()
	local floor = self:get_floor()
	floor.x -= 1
	return floor
end

function Character:get_floor_right()
	local floor = self:get_floor()
	floor.x += 1
	return floor
end

function Character:move_to(position)
	self.position = position:copy()
end

function Character:check_mobility()
	-- If the character is shooting, they can't move
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
	-- Get surroundings
	local self_tile = mget(self.map_pos:unpack())
	local below_pos = self:get_floor()
	local below_tile = mget(below_pos:unpack())
	local above_pos = self:get_ceiling()
	local above_tile = mget(above_pos:unpack())
	local left_pos = self:get_left()
	local left_tile = mget(self.map_pos.x - 1, self.map_pos.y)
	local right_pos = self:get_right()
	local right_tile = mget(self.map_pos.x + 1, self.map_pos.y)

	local touching_ladder = self_tile == LADDER_TILE or below_tile == LADDER_TILE
	local grounded = self:check_grounded()

	-- Check movement

	self.down_allowed = not grounded
	if below_tile == LADDER_TILE or grounded then
		self.state = STATE_STANDING
	else
		self.state = STATE_FALLING
	end

	self.up_allowed = false
	if touching_ladder then
		if not grounded then
			self.state = STATE_CLIMBING
		end
		if not ((self.position.y % 8 == 0) and not (self_tile == LADDER_TILE)) then
			self.up_allowed = true
		else
			self.state = STATE_STANDING
		end
	end
	if fget(above_tile, COLLISION_FLAG) or above_pos.y < level.mapY then
		self.up_allowed = false
	end
	if self_tile == SHIMMY_TILE and self.position.y % 8 == 0 then
		self.up_allowed = false
		self.state = STATE_SHIMMYING
	end

	self.left_allowed = not fget(mget(left_pos:unpack()), COLLISION_FLAG) and not (left_pos.x < level.mapX)
	self.right_allowed = not fget(mget(right_pos:unpack()), COLLISION_FLAG) and not (right_pos.x > level.mapX + 15)

	self.shoot_left_allowed = mget(self:get_floor_left():unpack()) == BRICK_TILE and not fget(left_tile, BLOCK_ZAP_FLAG)
	self.shoot_right_allowed = mget(self:get_floor_right():unpack()) == BRICK_TILE and not fget(right_tile, BLOCK_ZAP_FLAG)
end

function Character:get_input()
	printh("This shouldn't run")
end

function Character:check_grounded()
	local floor = self:get_floor()
	local floor_tile = mget(floor:unpack())
	return flr(floor.y) >= (level.mapY + 16) or (fget(floor_tile, COLLISION_FLAG) and not (floor_tile == ONE_WAY_BRICK)) or self:check_standing_on_enemy()
end

function Character:check_standing_on_enemy()
	for e in all(enemies) do
		if abs(self.position.x - e.position.x) <= 4 then
			local vDistance = e.position.y - self.position.y
			if vDistance <= 8 and vDistance >= 7 then
				return true
			end
		end
	end
	return false
end

function Character:update_movement()
	-- the game nudges the player towards the center of the axis they are walking on
	if self.dx != 0 and self.dy != 0 then
		printh("Trying to move diagonally")
	else
		if self.dx != 0 or self.state == STATE_SHOOTING then
			if self.position.y % 8 >= 4 then
				self.dy = min(self.position.y % 8, SPEED)
			else
				self.dy = max(-(self.position.y % 8), -SPEED)
			end
		end
		if self.dy != 0 or self.state == STATE_FALLING or self.state == STATE_SHOOTING then
			if self.position.x % 8 >= 4 then
				self.dx = min(self.position.x % 8, SPEED)
			else
				self.dx = max(-(self.position.x % 8), -SPEED)
			end
		end
	end

	-- Resolve movement
	self.position.x += self.dx
	self.position.y += self.dy

	if self.state == STATE_FALLING then
		self.position.y += GRAVITY
	end
	if self:check_grounded() then
		self.position.y = flr(self.position.y / 8) * 8
	end
	if (self.dx != 0 or self.dy != 0) then
		if self.state == STATE_STANDING then
			self.state = STATE_WALKING
		elseif self.state == STATE_LADDER then
			self.state = STATE_CLIMBING
		end
	else
		if self.state == STATE_WALKING then
			self.state = STATE_STANDING
		elseif self.state == STATE_CLIMBING then
			self.state = STATE_LADDER
		end
	end
end

function Character:collide(other)
end

function Character:change_state(new_state)
	self.state = new_state
	self.animations[self.state]:start()
end

function Character:update()
	self.map_pos = self:get_tile()
	self:check_mobility()
	self:get_input()
	self:update_movement()
end

function Character:draw()
	local current_animation = self.animations[self.state]
	current_animation:draw(self.sprite, self.position.x, self.position.y, self.facing_left)
end
