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

--- Returns planar rotation in radians.
--- Rotation occurs around the Z axis and does not change elevation.
---@return number rotation Current rotation in radians.
function Entity:get_rotation()
    return self.transform.rotation
end

--- Changes planar rotation without changing position or elevation.
---@param rotation number New rotation in radians.
function Entity:set_rotation(rotation)
    assert(type(rotation) == "number", "entity rotation must be numeric")
    self.transform:set_rotation(rotation)
end

--- Assigns or replaces a named spatial shape.
--- The shape remains in local entity space and uses the entity transform in queries.
---@param name string Shape name.
---@param shape Shape Spatial shape instance.
function Entity:set_shape(name, shape)
    assert(type(name) == "string", "shape name must be a string")
    assert(shape ~= nil, "shape is required")

    self.shapes[name] = shape
end

--- Returns a named spatial shape.
---@param name string Shape name.
---@return Shape|nil shape Shape instance, or nil when absent.
function Entity:get_shape(name)
    return self.shapes[name]
end

--- Removes a named spatial shape.
--- This method does not return the removed shape.
---@param name string Shape name.
function Entity:remove_shape(name)
    self.shapes[name] = nil
end

--- Adds or replaces an event using event.id as its key.
---@param event EntityEvent Event containing a string identifier.
function Entity:add_event(event)
    assert(event ~= nil, "event is required")
    assert(type(event.id) == "string", "event id must be a string")

    self.events[event.id] = event
end

--- Returns an event by identifier.
---@param id string Event identifier.
---@return EntityEvent|nil event Event instance, or nil when absent.
function Entity:get_event(id)
    return self.events[id]
end

--- Removes an event by identifier.
--- This method does not return the removed event.
---@param id string Event identifier.
function Entity:remove_event(id)
    self.events[id] = nil
end

--- Returns whether this entity contains an event with the requested identifier.
---@param id string Event identifier.
---@return boolean exists True when the event exists.
function Entity:has_event(id)
    return self.events[id] ~= nil
end

--- Returns the live event table owned by this entity.
--- Changes made to the returned table affect the entity directly.
---@return table<string, EntityEvent> events Events indexed by identifier.
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
