---@meta

---@class MapEventVariables
---@field map_id string Map whose authored content received the signal.
---@field previous_map_id string? Previous region at dispatch time; nil when outside.
---@field current_map_id string? Destination at dispatch time; nil when outside.

---@class MapEventContext
---@field source EntityEvent Event definition that created this execution.
---@field entity Entity Original entity owning the event.
---@field activator Entity Original traveller that caused the map change.
---@field world table Shared runtime world.
---@field variables MapEventVariables Independent identifiers captured for this execution.
