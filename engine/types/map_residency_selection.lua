---@meta

---@class MapResidencyChanges
---@field revision integer Source-change counter; starts at zero and increases even when only order changes.
---@field added MapRegion[] Newly selected maps in new selection order.
---@field removed MapRegion[] Maps absent from the new selection, in previous selection order.
---@field retained MapRegion[] Maps present in both selections, in new selection order.

---@class MapResidencySelectionFields
---@field layout MapLayout Immutable source layout.
---@field current_map MapRegion? Last selected source region; nil outside the layout.
---@field maps MapRegion[] Read-only live selection: current region, then direct neighbors.
---@field maps_by_id table<string, MapRegion> Internal membership index containing original regions.
---@field changes MapResidencyChanges Read-only live report of the most recent source change.
