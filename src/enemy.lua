Enemy = {}
Enemy.__index = Enemy
setmetatable(Enemy, { __index = Character })

function Enemy:new()
    local instance = Character:new()
    setmetatable(instance, self)
    instance.sprite = 49
    return instance
end

function Enemy:get_input()
end
