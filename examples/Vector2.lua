local moss = require 'moss'

-- Simple example of a Vector2 class
-- making use of some basic metatable functions

---@class Vector2
---@field x number
---@field y number
local Vector2 = {}
local Vector2Mt = {__name = "Vector2"}

---@param x? number
---@param y? number
function Vector2:init(x, y)
    self.x = x or 0
    self.y = y or 0
end

---@return string
function Vector2:stringify()
    return string.format("(%s, %s)", self.x, self.y)
end

---@param otherVector Vector2
---@return Vector2
function Vector2:add(otherVector)
    return Vector2(self.x + otherVector.x, self.y + otherVector.y)
end

---@param scalar number
---@return Vector2
function Vector2:scale(scalar)
    return Vector2(self.x * scalar, self.y * scalar)
end

---@param otherVector Vector2
---@return number
function Vector2:dot(otherVector)
    return self.x * otherVector.x + self.y * otherVector.y
end

---@param otherVector Vector2
---@return boolean
function Vector2:isEqual(otherVector)
    return self.x == otherVector.x and self.y == otherVector.y
end

---@param v Vector2
function Vector2Mt.__tostring(v)
    return v:stringify()
end

---@param a Vector2
---@param b Vector2
---@return Vector2
function Vector2Mt.__add(a, b)
    return a:add(b)
end

function Vector2Mt.__mul(a, b)
    -- Have the `*` operator support `Vector * Vector`, `Vector * number` and `number * Vector`

    if type(a) == "table" and type(b) == "table" and moss.is(a, Vector2) and moss.is(b, Vector2) then
        return a:dot(b)
    end

    if type(b) == "number" then
        return a:scale(b)
    end

    return b:scale(a)
end

---@param a Vector2
---@param b Vector2
function Vector2Mt.__eq(a, b)
    return a:isEqual(b)
end

return moss.create(Vector2, Vector2Mt)