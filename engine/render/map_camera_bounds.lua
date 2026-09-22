---@class MapCameraBounds: MapCameraBoundsFields
local MapCameraBounds = {}
MapCameraBounds.__index = MapCameraBounds

--- Copies and validates map framing independently from map membership bounds.
---@param layout MapLayout Existing layout used to validate map identifiers.
---@param definitions table<string, CameraBounds> Rectangles indexed by map identifier.
---@param duration? number Finite transition duration in seconds; defaults to zero.
---@return MapCameraBounds configuration Shared, read-only camera configuration.
function MapCameraBounds.new(layout, definitions, duration)
  assert(layout ~= nil and type(layout.get_map) == "function",
    "map camera bounds require a map layout")
  assert(type(definitions) == "table", "map camera bounds require a maps table")
  if duration == nil then duration = 0 end
  assert(type(duration) == "number" and duration >= 0 and duration < math.huge,
    "map camera bounds duration must be finite and non-negative")

  local bounds_by_map = {}
  for id, bounds in pairs(definitions) do
    assert(type(id) == "string" and layout:get_map(id) ~= nil,
      "camera bounds reference unknown map: " .. tostring(id))
    assert(type(bounds) == "table", "camera bounds require a rectangle: " .. id)
    local copy = {}
    for _, name in ipairs({ "min_x", "min_y", "max_x", "max_y" }) do
      local value = bounds[name]
      assert(type(value) == "number" and value > -math.huge and value < math.huge,
        "camera bounds " .. id .. " require finite " .. name)
      copy[name] = value
    end
    assert(copy.max_x >= copy.min_x and copy.max_y >= copy.min_y,
      "camera maximum bounds must not be below minimum bounds: " .. id)
    bounds_by_map[id] = copy
  end

  return setmetatable({
    layout = layout, bounds_by_map = bounds_by_map, duration = duration
  }, MapCameraBounds)
end

--- Returns configured framing without allocating or applying fallback behavior.
---@param map_id? string Map identifier; nil represents a position outside the layout.
---@return CameraBounds? bounds Read-only rectangle, or nil without a configuration.
function MapCameraBounds:get_bounds(map_id)
  return self.bounds_by_map[map_id]
end

return MapCameraBounds
