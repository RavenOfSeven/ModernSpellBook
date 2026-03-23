-- MSB_Class.lua
-- Lua 5.0 compatible class system using metatables.
-- Works ONLY on custom Lua tables, NOT on WoW frame userdata.

function MSB_Class(base)
    local cls = {}
    cls.__index = cls

    if base then
        setmetatable(cls, { __index = base })
    end

    cls.New = function(self, a1, a2, a3, a4, a5)
        local instance = {}
        setmetatable(instance, cls)
        if instance.Init then
            instance:Init(a1, a2, a3, a4, a5)
        end
        return instance
    end

    return cls
end
