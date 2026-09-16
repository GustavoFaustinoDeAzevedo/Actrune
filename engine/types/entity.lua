---@meta

---@class EntityEvent
---@field id string Identifier used to store the event on an entity.

---@class EntityOptions
---@field id string Unique entity identifier.
---@field x? number Initial planar X coordinate.
---@field y? number Initial planar Y coordinate.
---@field rotation? number Initial planar rotation in radians.
---@field scale_x? number Initial horizontal scale.
---@field scale_y? number Initial vertical scale.
---@field shapes? table<string, Shape> Initial named spatial shapes.
---@field events? table<string, EntityEvent> Initial events indexed by identifier.
---@field components? table<string, any> Initial named components.

---@class EntityFields
---@field active boolean Runtime participation controlled by map activity for map-owned entities.
---@field id string Unique entity identifier.
---@field transform Transform Planar position, rotation and scale.
---@field shapes table<string, Shape> Spatial shapes indexed by name.
---@field events table<string, EntityEvent> Events indexed by identifier.
---@field components table<string, any> Components indexed by name.
