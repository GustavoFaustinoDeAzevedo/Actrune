---@meta

---@class SpatialLevelsFields
---@field elevations number[] Ordered elevations; array index 1 represents level 0.

---@class SpatialElevationOptions
---@field levels SpatialLevels Mapping used to resolve level elevations.
---@field level? integer Initial zero-based level. Defaults to 0.
---@field offset? number Initial displacement from the level. Defaults to 0.

---@class SpatialElevationFields
---@field levels SpatialLevels Shared level mapping.
---@field level integer Current zero-based reference level.
---@field offset number Vertical displacement relative to the reference level.
