---@meta

---@class MapRegionDefinition
---@field min_x number Inclusive lower world X.
---@field min_y number Inclusive lower world Y.
---@field max_x number Exclusive upper world X.
---@field max_y number Exclusive upper world Y.
---@field entities? string[] Authored content identifiers; omitted means no owned entities.
---@field neighbors? string[] Directed neighbor identifiers in declaration order; omitted means none.

---@class MapRegion: MapRegionDefinition
---@field id string Map identifier within its layout.
---@field entities string[] Read-only content identifiers copied during layout creation.
---@field neighbors string[] Read-only neighbor identifiers; reverse links must be declared separately.

---@class MapLayoutFields
---@field maps table<string, MapRegion> Read-only region definitions indexed by identifier.
---@field ordered_maps MapRegion[] Read-only regions in identifier order.
---@field neighbors_by_map table<string, MapRegion[]> Read-only resolved neighbor lists indexed by source map.