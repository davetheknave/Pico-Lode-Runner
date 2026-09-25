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

function GUI:draw_list(items, selection, x, y, w, h)
    self:draw_window(x, y, w, h)
    local index = 0
    for i in all(items) do
        print(i, self.xOffset + x + 2 + 4, self.yOffset + y + 7 * index + 2)
        index += 1
    end
    circ(self.xOffset + x + 3, self.yOffset + y + 4 + 7 * selection, 1)
end

function GUI:draw_grid(items, selected, x, y, w, h, cols)
    self:draw_window(x, y, w, h)
    local rows = ceil(#items / cols)
    for row = 1, rows do
        for column = 1, cols do
            local index = (row - 1) * cols + column
            if index <= #items then
                local itemX = self.xOffset + x + (column - 1) * (w - 2) / cols + 2
                local itemY = self.yOffset + y + (row - 1) * (h - 2) / rows + 2
                self:draw_grid_item(items[index], index == selected, itemX, itemY, (w - 2) / cols - 1, (h - 2) / rows - 1)
            end
        end
    end
end

function GUI:draw_grid_item(text, selected, x, y, w, h)
    if selected then
        rrectfill(x, y, w - 1, h - 1, 1, 3)
    else
        rrectfill(x, y, w - 1, h - 1, 1, 4)
    end
    print(text, x + w / 2 - (4 * #text / 2), y + h / 2 - 3, 1)
end

function GUI:make_grid(items, x, y, w, h, onChoose)
    local window = Window:new(self)
    local cols = 4
    window.selected = 0
    window.onX = function() self:close_window() end
    window.onO = function() self:close_window() onChoose(window.selected) end
    window.onUp = function()
        window.selected = window.selected - cols
        if window.selected < 0 then
            window.selected = ceil(#items / cols) * cols + window.selected
        end
        if window.selected >= #items then
            window.selected -= cols
        end
    end
    window.onDown = function()
        window.selected = window.selected + cols
        if window.selected >= #items then
            window.selected = window.selected - ceil(#items / cols) * cols
        end
        if window.selected < 0 then
            window.selected += cols
        end
    end
    window.onLeft = function()
        -- window.selected = (window.selected - 1) % #items
        window.selected = (window.selected - 1) % cols + flr(window.selected / cols) * cols
        if window.selected >= #items then
            window.selected = #items - 1
        end
    end
    window.onRight = function()
        -- window.selected = (window.selected + 1) % #items
        window.selected = (window.selected + 1) % cols + flr(window.selected / cols) * cols
        if window.selected >= #items then
            window.selected = flr(#items / cols) * cols
        end
    end
    window.draw = function() self:draw_grid(items, window.selected + 1, x, y, w, h, cols) end
    add(self.windows, window)
    return window
end

function GUI:make_textbox(message)
    local window = Window:new(self)
    window.onX = function() self:close_window() end
    window.onO = function() self:close_window() end
    window.draw = function() self:draw_bottom_text(message) end
    add(self.windows, window)
    return window
end
