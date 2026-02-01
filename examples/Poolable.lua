local moss = require 'moss'

-- More advanced Moss class example,
-- any class definition that inherits from this class
-- will (as long as it doesn't override the `__new` special metamethod)
-- be able to be stored into a simple pool after it's done being used,
-- and then be pulled back from that pool when trying to instance a new class
-- instead of actually creating a brand new table.

---@class Poolable
---@field pool table
local Poolable = {}
local PoolableMT = {}

Poolable.pool = {}

-- Any time a class inherits from this class,
-- a static `pool` field will be inserted into its definition
-- (similarly to how `Poolable.pool = {}` is set above)
function PoolableMT.__inherit(newClass)
    newClass.pool = {}
end

-- When this class (or a class implementing it)
-- creates a new instance, it will, if available,
-- be pulled from the pool.
function PoolableMT.__new(class, metatable, ...)
    if class.pool[#class.pool] then
        local inst = class.pool[#class.pool]
        class.pool[#class.pool] = nil -- pop it
        return inst
    end
    return moss.generateInstance(class, ...) -- pool empty, generate new one
end

--- This should be called on an instance just before it's discarded
--- to make it able to be pooled again later
function Poolable:enpool()
    self.pool[#self.pool + 1] = self
end

return moss.create(Poolable, PoolableMT)