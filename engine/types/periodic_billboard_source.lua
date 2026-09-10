---@meta

---@class PeriodicBillboardSourceOptions
---@field padding number World-space margin covering visual extent from the anchor.
---@field elevation_scale number Same elevation scale used by the orthographic projection.

---@class PeriodicBillboardSourceFields
---@field source table Original source exposing get_entries.
---@field topology WorldTopology Map repetition configuration.
---@field camera table Orthographic camera.
---@field padding number Extra viewport margin in world units.
---@field elevation_scale number Visual displacement per Z unit.
---@field entries table[] Reused output entries.
---@field copies table[] Reusable storage for visual repetitions.
