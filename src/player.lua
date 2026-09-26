Player = {}
Player.__index = Player
setmetatable(Player, { __index = Character })

function Player:get_input()
	self.dx = 0
	self.dy = 0
	if self.state != STATE_FALLING and self.state != STATE_SHOOTING and self.state != STATE_DYING then
		if not (btn(0) and btn(1)) then
			if self.left_allowed and btn(0) then
				-- left
				self.facing_left = true
				self.dx = -SPEED
			elseif self.right_allowed and btn(1) then
				--right
				self.dx = SPEED
				self.facing_left = false
			end
		end

		-- can't move vertical and horizontal. vertical has priority
		if not (btn(2) and btn(3)) then
			if self.up_allowed and btn(2) then
				-- up
				self.dx = 0
				self.dy = -SPEED
			elseif self.down_allowed and btn(3) then
				-- down
				self.dx = 0
				self.dy = SPEED
			end
		end

		if self.shoot_left_allowed and btn(4) then
			-- O
			self:shoot(true)
			self.facing_left = true
			self.state = STATE_SHOOTING
			self.last_state_change = time()
			self.dx = 0
			self.dy = 0
		end
		if self.shoot_right_allowed and btn(5) then
			-- X
			self:shoot(false)
			self.facing_left = false
			self.state = STATE_SHOOTING
			self.last_state_change = time()
			self.dx = 0
			self.dy = 0
		end
	end
	if self.dx != 0 or self.dy != 0 or self.state == STATE_SHOOTING then
		self.has_moved = true
	end
end

function Player:collide(other)
	if manhattan_distance(self:pos(), other:pos()) <= 1 then
		lose()
	end
end

function Player:update()
	self:check_mobility()
	self:get_input()
	self:update_movement()
	-- game logic
	local next_tile = get_tile(self:pos())
	if next_tile == GOLD_TILE then
		self:get_gold(self:pos())
	end
	self:update_animation()
end

function Player:new()
	local instance = Character:new()
	setmetatable(instance, self)
	instance.sprite = 1
	instance.has_moved = false
	return instance
end

function Player:reset()
	self.state = STATE_STANDING
	self.animation = STATE_STANDING
	self.frame = 0
	self.has_moved = false
	self.facing_left = false
end

function Player:draw()
	if self.has_moved then
		Character.draw(self)
	else
		if frame % 8 > 3 then
			Character.draw(self)
		end
	end
end
