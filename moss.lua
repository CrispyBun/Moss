local moss = {}
local META_KEY = setmetatable({}, {__tostring = function() return "[Meta]" end})
local TREE_KEY = setmetatable({}, {__tostring = function() return "[Inheritance]" end})

------------------------------------------------------------
local function copyTo(source, target)
    if source then
        for key, value in pairs(source) do
            target[key] = value
        end
    end
    return target
end

local mossClassMT = {
    __call = function (t, ...)
        local inst = setmetatable({}, t[META_KEY])
        if inst.constructor then inst:constructor(...) end
        return inst
    end,
    __name = "Moss Class"
}
------------------------------------------------------------

------------------------------------------------------------
--- ### moss.inherit(...parents)
--- ### moss.extend(...parents)
--- Returns a class definition table with values inherited from the given parent classes.  
--- Example usage:
--- ```
--- local Rectangle = require 'Rectangle'
--- local Clickable = require 'Clickable'
--- 
--- local Button = moss.inherit( Rectangle, Clickable )
--- ```
---@param ... table|fun(): table The classes to inherit from
---@return table class
function moss.inherit(...)
    local parents = {...}
    local classTable = {}

    local allParents = {}

    for parentIndex = #parents, 1, -1 do
        local parent = parents[parentIndex]
        allParents[parent] = true

        if type(parent) == "function" then parent = parent() end

        if parent[TREE_KEY] then
            for prevParent in pairs(parent[TREE_KEY]) do
                allParents[prevParent] = true
            end
        end

        for key, value in pairs(parent) do
            classTable[key] = value
        end
    end

    classTable[TREE_KEY] = allParents

    return classTable
end
moss.extend = moss.inherit

------------------------------------------------------------
--- ### moss.create(class)
--- Sets the necessary metatable properties of the class and returns it.  
--- Calling the class ( `class()` ) after this will create an instance of it.  
--- Example usage:  
--- ---
--- #### Player.lua
--- ```
--- local moss = require 'moss'
---
--- local Player = {}
--- player.x = 0
--- player.y = 0
---
--- return moss.create(Player)
--- ```
--- ---
--- #### main.lua
--- ```
--- local Player = require 'Player'
--- local instance = Player()
--- ```
---@generic T
---@param class T A table defining the class' default values and methods
---@param metatable? table An optional metatable to be given to instances of this class
---@return table|fun(...): T
function moss.create(class, metatable)
    local mt = {}
    copyTo(class[META_KEY], mt)
    copyTo(metatable, mt)
    mt.__index = class

    class[TREE_KEY] = class[TREE_KEY] or {}
    class[TREE_KEY][class] = true

    class[META_KEY] = mt

    setmetatable(class, mossClassMT)

    return class
end

------------------------------------------------------------
--- ### moss.is(instance, class)
--- ### moss.implements(instance, class)
--- Checks if an instance was instanced from a class, or from a child of the class.  
--- Example usage:
--- ```
--- local ArmedEnemy = require 'ArmedEnemy'
--- 
--- if moss.is(someInst, ArmedEnemy) then
---     someInst:disarm()
--- end
--- ```
---@param instance table The instance to check
---@param class table|fun(): table The class to check for
---@return boolean
function moss.is(instance, class)
    return instance[TREE_KEY][class] or false
end
moss.implements = moss.is

return moss