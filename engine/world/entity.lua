local Transform = require("engine.world.transform")

local Entity = {}
Entity.__index = Entity

-- Creates a new entity with an identifier and spatial transform.
function Entity.new(options)
    assert(type(options) == "table", "options must be a table")
    assert(type(options.id) == "string", "entity id must be a string")

    local self = setmetatable({}, Entity)

    self.id = options.id

    self.transform = Transform.new({
        x = options.x,
        y = options.y,
        rotation = options.rotation,
        scale_x = options.scale_x,
        scale_y = options.scale_y
    })

    return self
end

-- Returns the current position of this entity.
function Entity:get_position()
    return self.transform.x, self.transform.y
end

-- Changes the entity position in world space.
function Entity:set_position(x, y)
    self.transform:set_position(x, y)
end

return Entity