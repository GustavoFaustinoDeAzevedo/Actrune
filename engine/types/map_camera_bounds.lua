---@meta

---@class MapCameraBoundsFields
---@field layout MapLayout Shared layout used to validate map identifiers.
---@field bounds_by_map table<string, CameraBounds> Read-only framing rectangles indexed by map id.
---@field duration number Default bounds transition duration in seconds.
