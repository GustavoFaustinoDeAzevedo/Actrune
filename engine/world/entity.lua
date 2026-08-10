local Transform = require("engine.world.transform")

local Entity = {}
Entity.__index = Entity

-- Creates a new entity with an identifier, transform, and optional spatial shapes.
function Entity.new(options)
    assert(type(options) == "table", "options must be a table")
    assert(type(options.id) == "string", "entity id must be a string")

    local self = setmetatable({}, Entity)

    self.id = options.id
    self.shapes = options.shapes or {}

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

-- Assigns a spatial shape to this entity under the given name.
function Entity:set_shape(name, shape)
    assert(type(name) == "string", "shape name must be a string")
    assert(shape ~= nil, "shape is required")

    self.shapes[name] = shape
end

-- Returns the spatial shape assigned to the given name.
function Entity:get_shape(name)
    return self.shapes[name]
end

-- Removes the spatial shape assigned to the given name.
function Entity:remove_shape(name)
    self.shapes[name] = nil
end

return Entity