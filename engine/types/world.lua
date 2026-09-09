---@meta

---@class WorldFields
---@field entities table<string, Entity> Entities indexed by their identifiers.
---@field topology WorldTopology? Optional map coordinate configuration.

---@class SpatialBounds
---@field min_x number Lower world X.
---@field min_y number Lower world Y.
---@field max_x number Upper world X.
---@field max_y number Upper world Y.

---@class WorldSweepHit
---@field entity Entity Original logical target.
---@field source_shape table Original moving shape.
---@field target_shape table Original target shape.
---@field fraction number Contact fraction along requested travel.
---@field normal_x number Contact normal X.
---@field normal_y number Contact normal Y.
---@field point_x number Contact X in the source's continuous coordinate frame.
---@field point_y number Contact Y in the source's continuous coordinate frame.
