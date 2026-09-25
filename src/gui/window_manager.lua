Window = {}
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
    local instance = setmetatable(
        {
            windows = {},
            xOffset = x,
            yOffset = y
        }, self
    )
    return instance
end

function GUI:close_window()
    deli(self.windows)
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
