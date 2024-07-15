# Moss
Moss is a library which was mainly made to ease the usual required boilerplate to make classes and inheritance the standard way in Lua.

It also adds other features, though, such as constructors or checking if a class instance was instanced from a certain class.

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
local Enemy = moss.inherit( Entity ) -- Or moss.extend( Entity )

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
Constructors can be made by adding a method named "init".
```lua
local Inventory = {}

function Inventory:init(items)
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

function Vector2:init(x, y)
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

-- Or alternatively:
print(moss.implements(Child, Parent))
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

-- Type of 'inst' here will be Message
local inst = Message()
```

# Advanced features
Moss provides the ability to change how it behaves with certain classes using its own special metamethods.

I do recommend having a gist of how the internals of the library work to use these though, as the advanced features allow you to do weird things and break stuff.
Also, these totally violate many OOP principles.

## __new
```lua
function meta.__new(class, metatable, ...)
```
If a class' metatable has the `__new` metamethod, when moss is tasked to create the instance of the class (by calling the class table),
it calls this metamethod instead of instancing it itself. The function should then return the new instance. (this means that, if you really want to, you can return something completely different instead of the actual class' instance)

The function is passed the class that is being instanced, the metatable that should be used for the class' instances, and a vararg of arguments passed into the constructor.

To actually create a proper instance, you can make a new table, set its metatable to the metatable passed as an argument, and call the constructor if there is one.
Or, you can use the `moss.generateInstance(class, ...)` function, which does exactly that.

```lua
-- Recreate default behavior with __new
function meta.__new(class, metatable, ...)
    local instance = setmetatable({}, metatable)
    if instance.init then instance:init(...) end
    return instance

    -- or:
    -- return moss.generateInstance(class, ...)
end
```

## __inherit
```lua
function meta.__inherit(class, metatable)
```
The `__inherit` metamethod acts not on instances, but on classes themselves. If a class has this metamethod, when another class inherits from it, this metamethod is called. It receives the class that's inheriting this one, and the metatable of that class' instances.

This can be used to inject values into the definition of inheriting classes that aren't actually defined in the base class.

```lua
function meta.__inherit(class, metatable)
    -- The class will have these in its definition
    class.num = 10
    metatable.__tostring = function ()
        return "I can even add metamethods!"
    end
end
```

## __create
```lua
function meta.__create(class, metatable)
```
The `__create` metamethod works similarly to the `__inherit` metamethod, but is simply called when this class is created (that is, when `moss.create()` is called on it).

While may seem there's not much point in that, do note that metamethods are inherited too, so any class that inherits from this class will *also* call this function whenever it's created. This can be used to define some rules that a class must follow if it inherits from this class, or inject fields based on what fields a class already has.

```lua
function meta.__create(class, metatable)
    -- Classes implementing this class will not have this variable defined, no matter what
    class.forbidden = nil

    -- Classes implementing this class must have either both width and height variables, or neither - they cannot have just one
    if class.width and not class.height then class.height = 0 end
    if class.height and not class.width then class.width = 0 end
end
```

# Why the name Moss?
It sounds nice :-)
