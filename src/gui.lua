GUI = {
    windows = {},
    xOffset = 0,
    yOffset = 0
}
GUI.__index = GUI

function GUI:new(x, y)
    local instance = setmetatable({}, self)
    self.xOffset = x
    self.yOffset = y
    return instance
end

function GUI:draw_window(x, y, w, h)
    local cornerthing = 1
    local outline_color = 0
    local fill_color = 1
    rrectfill(self.xOffset + x, self.yOffset + y, w, h, 1, fill_color)
    rrect(self.xOffset + x, self.yOffset + y, w, h, 1, outline_color)
    circfill(self.xOffset + x, self.yOffset + y, cornerthing, outline_color)
    circfill(self.xOffset + x + w - 1, self.yOffset + y, cornerthing, outline_color)
    circfill(self.xOffset + x, self.yOffset + y + h - 1, cornerthing, outline_color)
    circfill(self.xOffset + x + w - 1, self.yOffset + y + h - 1, cornerthing, outline_color)
end

function GUI:draw_textbox(message, x, y, w, h)
    local padding = 3
    self:draw_window(x, y, w, h)
    print(message, self.xOffset + x + padding, self.yOffset + y + padding)
end

function GUI:draw_bottom_text(message)
    local text_height = 7
    self:draw_textbox(message, 1, 109, 126, text_height * 2 + 4)
end

function GUI:draw_list(items, x, y, h, w)
    self:draw_window(2, 2, 50, 50)
    local index = 0
    for i in all(items) do
        print(i, self.xOffset + x + 2, self.yOffset + y + 7 * index + 2)
        index += 1
    end
end

function GUI_draw_grid(items)
end

function GUI_draw_grid_item(text)
end

-- returns false if input shouldn't continue to bubble
function GUI:handle_input()
    return false
end

function GUI:draw()
    self:draw_list({ "item 1", "item 2", "item 3" }, 2, 2, 50, 50)
end

-- four selections, yes no, popup, items, pkmn, stats screen, multi window
