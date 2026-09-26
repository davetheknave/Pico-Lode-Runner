function make_animation(a)
    local output = a or {
        frames = {}
    }
    function output:start()
        self.dt = 0
    end
    local function draw_frame(sprite_offset, frame, x, y, flip)
        -- not equals is used as exclusive or, to ensure double flip is just not flipped
        spr(frame.sprite + sprite_offset, x, y + (frame.bounce or 0), 1, 1, not flip != not frame.flip)
    end
    function output:draw(sprite_offset, x, y, flip)
        self.dt = self.dt or 0
        self.dt += 1 / 30
        local index = flr(self.dt / ANIMATION_RATE * 30) % #self.frames + 1
        local frame = self.frames[index]
        draw_frame(sprite_offset, frame, x, y, flip)
    end
    return output
end
