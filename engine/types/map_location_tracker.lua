---@meta

---@alias MapLocationChanged fun(entity: Entity, previous: MapRegion?, current: MapRegion?)

---@class MapLocationTrackerFields
---@field layout MapLayout Read-only layout used for membership queries.
---@field entity Entity Original entity instance being observed.
---@field current_map MapRegion? Last sampled region; nil outside every map.
