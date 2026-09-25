function GUI:make_main_menu(choose)
    local levels = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17" }
    local grid = self:make_grid(levels, 2, 20, 124, 106, choose)
    grid.onX = nil
    local old_draw = grid.draw
    local title = "lode runner"
    local style = "\f7\^w\^t\^o!ff"
    grid.draw = function()
        cls(1)
        old_draw()
        print(style .. title, self.xOffset + 64 - (#title / 2 * 8), 4, 0)
    end
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
