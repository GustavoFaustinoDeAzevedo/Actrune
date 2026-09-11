---@meta

---@class ResidentMap
---@field region MapRegion Read-only map definition.
---@field entities Entity[] Read-only membership containing original entity instances.

---@class ResidentMapCollectionFields
---@field maps table<string, ResidentMap> Resident content indexed by map identifier.
---@field owner_by_entity table<Entity, ResidentMap> Authored ownership indexed by original instance.
---@field shared_entities Entity[] Project entities without a map assignment, in declaration order.
