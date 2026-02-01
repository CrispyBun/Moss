local moss = require 'lib.moss'

-- More advanced Moss class example,
-- any class definition that inherits from this class
-- will (as long as it doesn't override the `__new` special metamethod)
-- act as a singleton and instancing it multiple times will always yield the same instance.

---@class Singleton
local Singleton = {}
local SingletonMT = {__name = "Singleton"}

local INSTANCES = {}

function SingletonMT.__new(class, metatable, ...)
    if INSTANCES[class] then return INSTANCES[class] end

    local inst = moss.generateInstance(class, ...)
    INSTANCES[class] = inst
    return inst
end

return moss.create(Singleton, SingletonMT)