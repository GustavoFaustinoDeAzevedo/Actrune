---@class MapLocationTracker: MapLocationTrackerFields
local MapLocationTracker = {}
MapLocationTracker.__index = MapLocationTracker

--- Tracks an existing entity within an immutable, non-overlapping map layout.
--- Captures the initial region without reporting an entry.
---@param layout MapLayout Regions expressed in global world coordinates.
---@param entity Entity Existing entity whose XY position will be sampled.
---@return MapLocationTracker tracker Independent location observer.
function MapLocationTracker.new(layout, entity)
  assert(layout ~= nil and type(layout.find_map) == "function",
    "map location tracker requires a map layout")
  assert(entity ~= nil and type(entity.get_position) == "function",
    "map location tracker requires an entity position")

  local x, y = entity:get_position()
  return setmetatable({
    layout = layout,
    entity = entity,
    current_map = layout:find_map(x, y)
  }, MapLocationTracker)
end

--- Returns the last sampled region without performing another lookup.
---@return MapRegion|nil map Current region, or nil outside the layout.
function MapLocationTracker:get_map()
  return self.current_map
end

--- Samples the entity origin once and reports a change between observed regions.
--- Reuses the current region while inside its bounds; searches only after leaving it.
--- Does not enumerate intermediate regions crossed between samples or modify the entity.
---@return boolean changed Whether the observed region changed.
---@return MapRegion|nil previous Region before this sample.
---@return MapRegion|nil current Region after this sample.
function MapLocationTracker:refresh()
  local x, y = self.entity:get_position()
  local previous = self.current_map

  if previous ~= nil and x >= previous.min_x and x < previous.max_x
    and y >= previous.min_y and y < previous.max_y then
    return false, previous, previous
  end

  local current = self.layout:find_map(x, y)
  self.current_map = current
  return current ~= previous, previous, current
end

return MapLocationTracker