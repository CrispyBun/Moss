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

moss.META_KEY = META_KEY -- Used to get the metatable of classes. There's not many uses for using this, but it's exposed anyway.
moss.TREE_KEY = TREE_KEY -- Used to get the inheritance information of classes. There's not many uses for using this, but it's exposed anyway.

-- If true, when inheriting from multiple classes, and the library finds
-- different implementations for the same method in the child's direct parents, it will force the child class
-- to disambiguate the methods by overriding and defining them itself.  
-- (If it doesn't, the methods will be replaced by a dummy function that errors if you try to use it.)
--
-- This may have undesirable results if you mix function types with other types for the same key in a class tree.
moss.diamondDisambiguation = false

------------------------------------------------------------

local function ambiguousMethodError()
    error("The method called is ambiguous due to it being implemented differently in multiple parent classes. It must be overridden in the inheriting class to disambiguate it.", 2)
end

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

--- Returns the metatable which the instances of the given moss class get assigned.  
--- You most likely won't need to use this method for most purposes, but it's here anyway since otherwise it's a bit awkward to get access to this metatable.
---@param class table|fun(): table The class definition
---@return table Metatable The metatable used by the class' instances
function moss.getInstanceMetatable(class)
    return class[META_KEY]
end

local mossClassMT = {
    __call = function (t, ...)
        local metatable = t[META_KEY]
        if metatable and metatable.__new then return metatable.__new(t, metatable, ...) end

        return moss.generateInstance(t, ...)
    end,
    __tostring = function (t)
        return t[META_KEY] and t[META_KEY].__name or "Moss Class"
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
--- 
--- return moss.create(Button)
--- ```
---@param ... table|fun(): table The classes to inherit from
---@return table class
function moss.inherit(...)
    local parents = {...}
    local classTable = {}

    local allParents = {}
    local metatable = {}

    local seenMethods = {}
    local inheritMethods = {}

    local forcedValues = {}

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

            if moss.diamondDisambiguation and type(value) == "function" then
                if seenMethods[key] and seenMethods[key] ~= value then
                    forcedValues[key] = ambiguousMethodError
                elseif not seenMethods[key] then
                    seenMethods[key] = value
                end
            end
        end
    end

    metatable.__name = nil -- Don't inherit class names for clarity
    classTable[TREE_KEY] = allParents
    classTable[META_KEY] = metatable

    for key, value in pairs(forcedValues) do
        classTable[key] = value
    end

    for methodIndex = 1, #inheritMethods do
        inheritMethods[methodIndex](classTable, metatable)
    end

    return classTable
end
moss.extend = moss.inherit

------------------------------------------------------------
--- ### moss.create(class)
--- Sets the necessary metatable properties of the class and returns it.  
--- Calling the class definition ( `Class()` ) after this will create an instance of it.  
--- 
--- Example usage:  
--- #### Player.lua
--- ```
--- local moss = require 'moss'
---
--- local Player = {}
--- Player.x = 0
--- Player.y = 0
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
---@return T|fun(...: unknown): T
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

------------------------------------------------------------
--- A basic class which can be used as a base for other classes.  
--- Has basic type checking methods and an empty constructor.
---@class Moss.BaseClass
local BaseClass = {}

BaseClass.is = moss.is
BaseClass.implements = moss.implements
BaseClass.type = moss.type
function BaseClass:init() end

--- You can optionally inherit from this class to get a base for your classes.  
--- Has basic type checking methods and an empty constructor,
--- so all classes inheriting from this one are guaranteed to have a constructor.
moss.BaseClass = moss.create(BaseClass, {__name = "MossBaseClass"})
------------------------------------------------------------

-- Class commons compat:
-- (https://github.com/bartbes/Class-Commons)

---@diagnostic disable-next-line: undefined-global
if not common then
    ---@diagnostic disable-next-line: lowercase-global
    common = {}

    ---@generic T
    ---@param name string? The name of the class
    ---@param table T The class definition
    ---@param ... table|fun(): table The classes to inherit from
    ---@return table|fun(...: unknown): T class The instancable class
    function common.class(name, table, ...)
        local base = moss.inherit(...)

        -- Class commons inherits when creating the class, moss requires it to be done beforehand,
        -- so the best solution is to just inject the fields as if they were inherited first:
        for key, value in pairs(base) do
            table[key] = table[key] == nil and value or table[key]
        end

        return moss.create(table, {__name = name})
    end

    ---@generic T
    ---@param class T The class to instance
    ---@param ... unknown Arguments for the constructor
    ---@return T
    function common.instance(class, ...)
        return class(...)
    end

    -- This isn't in the standard but why not add it anyway:

    ---@param instance table The instance to check
    ---@param class table|fun(): table The class to check for
    ---@return boolean
    function common.instanceof(instance, class)
        return moss.is(instance, class)
    end
end

------------------------------------------------------------

return moss