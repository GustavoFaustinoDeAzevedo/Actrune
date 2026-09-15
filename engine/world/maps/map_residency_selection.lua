---@class MapResidencySelection: MapResidencySelectionFields
local MapResidencySelection = {}
MapResidencySelection.__index = MapResidencySelection

--- Creates an empty desired selection without loading or unloading map content.
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
    maps_by_id = {}
  }, MapResidencySelection)
end

--- Selects the current map followed by its direct neighbors in declaration order.
--- Passing nil clears the selection; an unchanged source keeps the existing result.
--- Reuses selection tables and original region instances.
---@param map MapRegion? Current region from this layout, or nil when outside.
function MapResidencySelection:set_current_map(map)
  assert(map == nil or (type(map) == "table" and self.layout:get_map(map.id) == map),
    "residency selection map must belong to its layout")
  if self.current_map == map then return end

  local neighbors = map and self.layout:get_neighbors(map.id)
  assert(map == nil or type(neighbors) == "table",
    "selected map requires a resolved neighbor list")

  for index = #self.maps, 1, -1 do
    self.maps_by_id[self.maps[index].id] = nil
    self.maps[index] = nil
  end

  self.current_map = map
  if map == nil then return end

  self.maps[1] = map
  self.maps_by_id[map.id] = map
  for _, neighbor in ipairs(neighbors or {}) do
    self.maps[#self.maps + 1] = neighbor
    self.maps_by_id[neighbor.id] = neighbor
  end
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

return MapResidencySelection
