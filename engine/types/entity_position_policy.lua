---@meta

---@class EntityPositionPolicyOptions
---@field offset_x? number Fixed world X offset. Defaults to zero.
---@field offset_y? number Fixed world Y offset. Defaults to zero.
---@field elevation_source? SpatialElevation Live source of absolute Z.
---@field elevation_scale? number Visual displacement per Z unit. Defaults to one.
---@field topology? WorldTopology Optional map coordinate configuration.

---@class EntityPositionPolicyFields
---@field entity Entity Followed entity.
---@field offset_x number Fixed world X offset.
---@field offset_y number Fixed world Y offset.
---@field elevation_source SpatialElevation? Live elevation source.
---@field elevation_scale number Visual displacement per Z unit.
---@field topology WorldTopology? Optional map coordinate configuration.
