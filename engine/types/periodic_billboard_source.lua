---@meta

--- Supplies min_x, min_y, max_x and max_y in world coordinates, including the requested padding.
---@alias PeriodicBillboardBoundsProvider fun(padding: number): number, number, number, number

---@class PeriodicBillboardSourceOptions
---@field padding number World-space margin covering visual extent from the anchor.
---@field elevation_scale number Planar selection shift per Z unit; use zero for perspective.
---@field bounds_provider PeriodicBillboardBoundsProvider? Custom selection bounds; nil uses the orthographic viewport.

---@class PeriodicBillboardSourceFields
---@field source table Original source exposing get_entries.
---@field topology WorldTopology Map repetition configuration.
---@field camera table Camera supplying viewport and elevation displacement rotation.
---@field padding number Extra selection margin in world units.
---@field elevation_scale number Planar selection shift per Z unit.
---@field bounds_provider PeriodicBillboardBoundsProvider? Optional world bounds provider.
---@field entries table[] Reused output entries.
---@field copies table[] Reusable storage for visual repetitions.
