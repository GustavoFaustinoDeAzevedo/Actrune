---@meta

---@class MapResidencySelectionFields
---@field layout MapLayout Immutable source layout.
---@field current_map MapRegion? Last selected source region; nil outside the layout.
---@field maps MapRegion[] Read-only live selection: current region, then direct neighbors.
---@field maps_by_id table<string, MapRegion> Internal membership index containing original regions.
