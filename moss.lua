------------------------------------------------------------
-- A lightweight Lua class library
-- written by yours truly, CrispyBun.
-- crispybun@pm.me
-- https://github.com/CrispyBun/Moss
------------------------------------------------------------
--[[
MIT License

Copyright (c) 2024 Ava "CrispyBun" Špráchalů

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]
------------------------------------------------------------

local moss = {}
local META_KEY = setmetatable({}, {__tostring = function() return "[Metatable]" end})
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

--- Creates a new instance of a Moss class, bypassing the `__new` method (if any) and just using the default Moss one.  
--- You probably don't have to worry about this method, but its one good use is if you're implementing the `__new` method, and in it, you want to use the default Moss instancing.
---@param class table|fun(): table The class to instance
---@param ... unknown Arguments for the constructor
---@return table
function moss.generateInstance(class, ...)
    local inst = setmetatable({}, class[META_KEY])
    if inst.init then inst:init(...) end
    return inst
end

local mossClassMT = {
    __call = function (t, ...)
        local metatable = t[META_KEY]
        if metatable and metatable.__new then return metatable.__new(t, metatable, ...) end

        return moss.generateInstance(t, ...)
    end,
    __name = "Moss Class"
}
------------------------------------------------------------

------------------------------------------------------------
--- ### moss.inherit(...parents)
--- ### moss.extend(...parents)
--- Returns a class definition table with values inherited from the given parent classes (or from regular tables).  
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
    local metatable = {}

    local inheritMethods = {}

    for parentIndex = #parents, 1, -1 do
        local parent = parents[parentIndex]
        allParents[parent] = true

        -- Technically, the annotations suggest the parent can be a function.
        -- The parents should really only ever be tables, or tables that can be called for instancing,
        -- but the way that's annotated does imply it can be just a function that returns a table,
        -- so let's handle that too:
        if type(parent) == "function" then parent = parent() end

        if parent[TREE_KEY] then
            for prevParent in pairs(parent[TREE_KEY]) do
                allParents[prevParent] = true
            end
        end

        if parent[META_KEY] then
            for methodName, method in pairs(parent[META_KEY]) do
                metatable[methodName] = method
            end
            if parent[META_KEY].__inherit then inheritMethods[#inheritMethods+1] = parent[META_KEY].__inherit end
        end

        for key, value in pairs(parent) do
            classTable[key] = value
        end
    end

    classTable[TREE_KEY] = allParents
    classTable[META_KEY] = metatable

    for methodIndex = 1, #inheritMethods do
        inheritMethods[methodIndex](classTable, metatable)
    end

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

    if mt.__create then mt.__create(class, mt) end

    return class
end

------------------------------------------------------------
--- ### moss.is(instance, class)
--- ### moss.implements(instance, class)
--- ### moss.instanceof(instance, class)
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
    return instance[TREE_KEY] and instance[TREE_KEY][class] or false
end
moss.implements = moss.is
moss.instanceof = moss.is

------------------------------------------------------------
--- ### moss.type(instance)
--- ### moss.typeof(instance)
--- Returns the class definition the given moss instance was instanced from
---@param instance table
---@return table|fun(): table class The class definition
function moss.type(instance)
    return instance[META_KEY] and instance[META_KEY].__index
end
moss.typeof = moss.type

return moss