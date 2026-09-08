local Transform = require("engine.world.transform")

---@class Entity: EntityFields
local Entity = {}
Entity.__index = Entity

--- Creates an entity with a unique identifier and planar transform.
--- X and Y describe position on the 2D plane; elevation is supplied by a component.
---@param options EntityOptions Initial entity data.
---@return Entity entity New entity.
function Entity.new(options)
    assert(type(options) == "table", "options must be a table")
    assert(type(options.id) == "string", "entity id must be a string")

    local self = setmetatable({}, Entity)

    self.id = options.id
    self.shapes = options.shapes or {}
    self.events = options.events or {}
    self.components = options.components or {}

    self.transform = Transform.new({
        x = options.x,
        y = options.y,
        rotation = options.rotation,
        scale_x = options.scale_x,
        scale_y = options.scale_y
    })

    return self
end

--- Returns the current position on the 2D world plane.
--- This method does not include elevation or Z.
---@return number x Planar X coordinate.
---@return number y Planar Y coordinate.
function Entity:get_position()
    return self.transform.x, self.transform.y
end

--- Changes position on the 2D world plane without changing elevation.
---@param x number New planar X coordinate.
---@param y number New planar Y coordinate.
function Entity:set_position(x, y)
    self.transform:set_position(x, y)
end

-- Returns the current rotation of this entity in radians.
function Entity:get_rotation()
    return self.transform.rotation
end

-- Changes the entity rotation in world space.
function Entity:set_rotation(rotation)
    assert(type(rotation) == "number", "entity rotation must be numeric")
    self.transform:set_rotation(rotation)
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

-- Associates an event with this entity using the event identifier.
function Entity:add_event(event)
    assert(event ~= nil, "event is required")
    assert(type(event.id) == "string", "event id must be a string")

    self.events[event.id] = event
end

-- Returns the event associated with the given identifier.
function Entity:get_event(id)
    return self.events[id]
end

-- Removes the event associated with the given identifier.
function Entity:remove_event(id)
    self.events[id] = nil
end

-- Checks whether this entity has an event with the given identifier.
function Entity:has_event(id)
    return self.events[id] ~= nil
end

-- Returns all events currently associated with this entity.
function Entity:get_events()
    return self.events
end

--- Assigns or replaces a component under a name.
--- Existing references to the previous component are not updated automatically.
---@param name string Component name used for later lookup.
---@param component any Component instance.
function Entity:set_component(name, component)
    assert(name ~= nil, "component name is required")
    assert(component ~= nil, "component is required")

    self.components[name] = component
end

--- Returns a component by name.
--- The entity does not know the concrete type associated with each name.
---@param name string Component name.
---@return any component Component instance, or nil when absent.
function Entity:get_component(name)
    return self.components[name]
end

--- Returns whether a component is assigned under the requested name.
---@param name string Component name.
---@return boolean exists True when the component exists.
function Entity:has_component(name)
    return self.components[name] ~= nil
end

--- Removes and returns a named component.
--- Objects retaining a reference to that component keep their old reference.
---@param name string Component name.
---@return any component Removed component, or nil when absent.
function Entity:remove_component(name)
    local component =
        self.components[name]

    self.components[name] = nil

    return component
end

return Entity
