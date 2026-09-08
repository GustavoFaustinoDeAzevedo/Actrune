---@meta

---@class ElevationMoverOptions
---@field elevation_component string Name of the elevation component to move.
---@field source_shape string Name of the moving entity's horizontal collision shape.
---@field target_shape string Name of collision shapes considered on other entities.
---@field source_vertical_range string Name of the moving body's vertical range.
---@field target_vertical_range string Name of vertical ranges considered on other entities.

---@class ElevationMoverFields
---@field world table World exposing horizontal shape queries.
---@field entity table Entity moved by this operation.
---@field elevation SpatialElevation Live elevation component resolved during construction.
---@field source_range VerticalRange Live interval used to resolve the moving body's absolute Z bounds.
---@field source_shape string Moving entity's collision shape name.
---@field target_shape string Other entities' collision shape name.
---@field target_vertical_range string Other entities' vertical range component name.
