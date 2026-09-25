function GUI:make_level_select(choose)
    local levels = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17" }
    self:make_grid(levels, choose)
end
function GUI:make_yesno(startYes, onYes, onNo)
    local window = Window:new(self)
    window.yes = startYes
    window.onX = function() self:close_window() onNo() end
    window.onO = function() self:close_window() if window.yes then onYes() else onNo() end end
    window.onUp = function() window.yes = not window.yes end
    window.onDown = function() window.yes = not window.yes end
    window.draw = function() self:draw_list({ "yes", "no" }, not window.yes and 1 or 0, 107, 92, 20, 16) end
    add(self.windows, window)
    return window
end

function GUI:draw_bottom_text(message)
    local text_height = 7
    self:draw_textbox(message, 1, 109, 126, text_height * 2 + 4)
end
