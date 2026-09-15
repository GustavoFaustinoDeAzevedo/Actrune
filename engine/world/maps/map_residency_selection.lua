---@class MapResidencySelection: MapResidencySelectionFields
local MapResidencySelection = {}
MapResidencySelection.__index = MapResidencySelection

--- Clears a reusable map list without replacing its table.
---@param maps MapRegion[] List owned by this selection.
local function clear_maps(maps)
  for index = #maps, 1, -1 do maps[index] = nil end
end

--- Classifies a desired map and consumes its previous membership.
---@param selection MapResidencySelection Selection being updated.
---@param map MapRegion Desired region.
local function classify_map(selection, map)
  local changes = selection.changes
  local target = selection.maps_by_id[map.id] ~= nil and changes.retained or changes.added
  target[#target + 1] = map
  selection.maps_by_id[map.id] = nil
end

--- Creates an empty desired selection and its reusable change report.
---@param layout MapLayout Immutable layout containing resolved neighbor lists.
---@return MapResidencySelection selection Desired residency state.
function MapResidencySelection.new(layout)
  assert(layout ~= nil and type(layout.get_map) == "function"
    and type(layout.get_neighbors) == "function",
    "map residency selection requires a map layout")

  return setmetatable({
    layout = layout,
    current_map = nil,
    maps = {},
    maps_by_id = {},
    changes = { revision = 0, added = {}, removed = {}, retained = {} }
  }, MapResidencySelection)
end

--- Selects the current map and its direct neighbors, then reports membership changes.
--- Added and retained maps follow new order; removed maps follow previous order.
--- Repeating the same source preserves both selection and last report.
--- Passing nil clears desired membership without unloading content.
---@param map MapRegion? Current region from this layout, or nil when outside.
function MapResidencySelection:set_current_map(map)
  assert(map == nil or (type(map) == "table" and self.layout:get_map(map.id) == map),
    "residency selection map must belong to its layout")
  if self.current_map == map then return end

  local neighbors = map and self.layout:get_neighbors(map.id)
  assert(map == nil or type(neighbors) == "table",
    "selected map requires a resolved neighbor list")

  local changes = self.changes
  clear_maps(changes.added)
  clear_maps(changes.removed)
  clear_maps(changes.retained)

  if map ~= nil then
    classify_map(self, map)
    for _, neighbor in ipairs(neighbors or {}) do classify_map(self, neighbor) end
  end

  -- Remaining old memberships are absent from the desired selection.
  for index = 1, #self.maps do
    local previous = self.maps[index]
    if self.maps_by_id[previous.id] ~= nil then
      changes.removed[#changes.removed + 1] = previous
      self.maps_by_id[previous.id] = nil
    end
    self.maps[index] = nil
  end

  self.current_map = map
  if map ~= nil then
    self.maps[1] = map
    self.maps_by_id[map.id] = map
    for _, neighbor in ipairs(neighbors or {}) do
      self.maps[#self.maps + 1] = neighbor
      self.maps_by_id[neighbor.id] = neighbor
    end
  end
  changes.revision = changes.revision + 1
end

--- Returns a live view of the desired maps, with the current map first.
--- Treat the list as read-only; later selections update this same table.
---@return MapRegion[] maps Desired regions, not a snapshot of loaded content.
function MapResidencySelection:get_maps()
  return self.maps
end

--- Checks desired membership without searching the ordered list.
---@param id string Map identifier.
---@return boolean selected Whether this map belongs to the desired selection.
function MapResidencySelection:contains(id)
  return self.maps_by_id[id] ~= nil
end

--- Returns the last source-change report, not changes accumulated across updates.
--- The record and its lists are reused; save the numeric revision to detect a new report.
--- Initial selection adds all desired maps; unchanged-source calls retain the last report.
---@return MapResidencyChanges changes Read-only live report about desired membership.
function MapResidencySelection:get_changes()
  return self.changes
end

return MapResidencySelection
