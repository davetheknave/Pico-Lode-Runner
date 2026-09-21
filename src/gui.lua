Window = {
    owner = nil,
    draw = nil,
    onX = nil,
    onO = nil,
    onUp = nil,
    onDown = nil,
    onLeft = nil,
    onRight = nil
}

Window.__index = Window
function Window:new(owner)
    local instance = setmetatable({ owner = owner }, self)
    return instance
end

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

function GUI:init()
    self:make_textbox("hello!")
    self:make_yesno(true)
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

function GUI:draw_list(items, selection, x, y, h, w)
    self:draw_window(x, y, h, w)
    local index = 0
    for i in all(items) do
        print(i, self.xOffset + x + 2 + 4, self.yOffset + y + 7 * index + 2)
        index += 1
    end
    circ(self.xOffset + x + 3, self.yOffset + y + 4 + 7 * selection, 1)
end

function GUI_draw_grid(items)
end

function GUI_draw_grid_item(text)
end

function GUI:close_window()
    deli(self.windows)
end

function GUI:make_yesno(startYes)
    local window = Window:new(self)
    window.yes = startYes
    window.onX = function() self:close_window() end
    window.onO = function() self:close_window() end
    window.onUp = function() window.yes = not window.yes end
    window.onDown = function() window.yes = not window.yes end
    window.draw = function() self:draw_list({ "yes", "no" }, not startYes and 1 or 0, 107, 92, 20, 16) end
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

-- returns true if input shouldn't continue to bubble
function GUI:handle_input()
    if #self.windows > 0 then
        local top = self.windows[#self.windows]
        if btnp(4) then
            if top.onO != nil then
                top.onO()
            end
        elseif btnp(5) then
            if top.onX != nil then
                top.onX()
            end
        elseif btnp(2) then
            if top.onUp != nil then
                top.onUp()
            end
        elseif btnp(3) then
            if top.onDown != nil then
                top.onDown()
            end
        elseif btnp(1) then
            if top.onRight != nil then
                top.onRight()
            end
        elseif btnp(0) then
            if top.onLeft != nil then
                top.onLeft()
            end
        else
        end
        return true
    else
        return false
    end
end

function GUI:draw()
    for w in all(self.windows) do
        if w.draw != nil then
            w.draw()
        end
    end
end
