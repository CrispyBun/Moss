# Moss
Moss is a library mainly intended to ease the usual required boilerplate to make classes and inheritance the standard way in Lua. It also adds other features, though, such as constructors or checking if a class instance was made from a certain class.

# Boilerplate soothing
Here is vanilla lua code (assuming this is in `class/Enemy.lua`):  
```lua
local Entity = require 'class.Entity'

local Enemy = {}
local EnemyMetatable = {}
setmetatable(Enemy, EnemyMetatable)

-- Inheritance
EnemyMetatable.__index = Entity

-- Class' methods
function Enemy:hurt(damage)
    -- override existing method
    -- but still call the original
    Entity.hurt(self, damage)
    print("damaged enemy")
end

-- Make it possible to be instanced
EnemyMetatable.__call = function()
  return setmetatable({}, {__index = Enemy})
end

return Enemy
```
And here's how you can achieve the same effect with Moss:
```lua
local moss = require 'moss'
local Entity = require 'class.Entity'

-- Inheritance
local Enemy = moss.inherit( Entity )

-- Class' methods
function Enemy:hurt(damage)
    Entity.hurt(self, damage)
    print("damaged enemy")
end

-- Make it possible to be instanced
return moss.create(Enemy)
```

# Multiple inheritance
Is easy to do.
```lua
local Button = moss.inherit( Rectangle, Clickable )
```

# Constructors
Constructors can be made by adding a method named "constructor".
```lua
local Inventory = {}

function Inventory:constructor(items)
    self.items = {}
    for index, value in ipairs(items) do
        self.items[index] = value
    end
end
```

# Metamethods
Metamethods can still be implemented similarly to the vanilla Lua way.
```lua
local moss = require 'moss'

local Vector2 = {}
local Vector2Mt = {}

Vector2.x = 0
Vector2.y = 0

function Vector2:constructor(x, y)
    self.x = x or self.x
    self.y = y or self.y
end

function Vector2Mt.__tostring(v)
    return(string.format("(%s, %s)", v.x, v.y))
end

function Vector2Mt.__add(a, b)
    return Vector2(a.x + b.x, a.y + b.y)
end

return moss.create(Vector2, Vector2Mt) -- Pass the metatable as the second argument
```

# is
```lua
local moss = require 'moss'
local Parent = require 'class.Parent'
local Child = require 'class.Child'

print(moss.is(Child, Parent)) --> true
```

# Lua language server
Moss has been designed to work well with the [lua-language-server](https://github.com/LuaLS/lua-language-server) extension. You can easily annotate your classes and when instancing, the instances will be seen as the correct type.
```lua
---@class Message
---@field text string
local Message = {}

---@param msg string
function Message:set(msg)
    self.text = msg
end

return moss.create(Message)
```
```lua
local Message = require 'class.Message'

-- Type here will be Message
local message = Message()
```

# Why the name Moss?
It sounds nice :-)
