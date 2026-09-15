---@meta

---@class MapEventRetentionFields
---@field collection ResidentMapCollection Immutable authored entity ownership.
---@field scheduler table Scheduler exposing visit_pending_contexts.
---@field maps MapRegion[] Read-only live requirements from the last refresh.
---@field maps_by_id table<string, MapRegion> Current event requirement membership.
---@field pending_maps MapRegion[] Reused workspace for the next refresh.
---@field pending_by_id table<string, MapRegion> Reused membership workspace.
---@field revision integer Membership-change counter, initially zero.
