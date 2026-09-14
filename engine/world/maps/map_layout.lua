---@class MapLayout: MapLayoutFields
local MapLayout = {}
MapLayout.__index = MapLayout

--- Tests map membership using half-open bounds.
---@param map MapRegion Region being tested.
---@param x number Global world X.
---@param y number Global world Y.
---@return boolean inside Whether the point belongs to the region.
local function contains(map, x, y)
  return x >= map.min_x and x < map.max_x and y >= map.min_y and y < map.max_y
end

--- Copies a dense identifier list without retaining the authored table.
---@param values? string[] Declared identifiers.
---@param map_id string Map identifier used in validation errors.
---@param field string Definition field used in validation errors.
---@return string[] ids Independent list owned by the layout.
local function copy_ids(values, map_id, field)
  if values == nil then return {} end
  local label = "map " .. map_id .. " " .. field
  assert(type(values) == "table", label .. " must be a list")

  local count = 0
  for index in pairs(values) do
    assert(type(index) == "number" and index >= 1 and index % 1 == 0,
      label .. " must use positive integer indices")
    count = count + 1
  end

  local ids = {}
  for index = 1, count do
    local id = values[index]
    assert(type(id) == "string" and id ~= "",
      label .. " requires an identifier at index " .. index)
    ids[index] = id
  end
  return ids
end

--- Creates non-overlapping regions and resolves their declared neighbors once.
--- Neighbor links are directed and independent of geometric adjacency.
--- Copies definitions; returned regions and neighbor lists must be treated as read-only.
---@param definitions table<string, MapRegionDefinition> Definitions indexed by map identifier.
---@return MapLayout layout Resident map layout.
function MapLayout.new(definitions)
  assert(type(definitions) == "table" and next(definitions) ~= nil,
    "map layout requires at least one map")

  local self = setmetatable({
    maps = {}, ordered_maps = {}, neighbors_by_map = {}
  }, MapLayout)

  for id, definition in pairs(definitions) do
    assert(type(id) == "string" and id ~= "", "map identifiers must be non-empty strings")
    assert(type(definition) == "table", "map bounds must be a table: " .. id)

    for _, name in ipairs({ "min_x", "min_y", "max_x", "max_y" }) do
      local value = definition[name]
      assert(type(value) == "number" and value > -math.huge and value < math.huge,
        "map " .. id .. " requires finite " .. name)
    end

    local map = {
      id = id,
      min_x = definition.min_x,
      min_y = definition.min_y,
      max_x = definition.max_x,
      max_y = definition.max_y,
      entities = copy_ids(definition.entities, id, "entities"),
      neighbors = copy_ids(definition.neighbors, id, "neighbors")
    }

    assert(map.max_x > map.min_x and map.max_y > map.min_y,
      "map bounds must have positive dimensions: " .. id)

    for _, other in ipairs(self.ordered_maps) do
      local overlaps = map.min_x < other.max_x and other.min_x < map.max_x
          and map.min_y < other.max_y and other.min_y < map.max_y
      assert(not overlaps, "map regions overlap: " .. id .. " and " .. other.id)
    end

    self.maps[id] = map
    self.ordered_maps[#self.ordered_maps + 1] = map
  end

  table.sort(self.ordered_maps, function(a, b) return a.id < b.id end)

  for _, map in ipairs(self.ordered_maps) do
    local neighbors, seen = {}, {}
    for _, id in ipairs(map.neighbors) do
      assert(id ~= map.id, "map cannot reference itself as a neighbor: " .. map.id)
      assert(self.maps[id] ~= nil, "map " .. map.id .. " references unknown neighbor: " .. id)
      assert(not seen[id], "map " .. map.id .. " repeats neighbor: " .. id)
      seen[id] = true
      neighbors[#neighbors + 1] = self.maps[id]
    end
    self.neighbors_by_map[map.id] = neighbors
  end

  return self
end

--- Returns the resident region definition associated with an identifier.
---@param id string Map identifier.
---@return MapRegion|nil map Read-only region, or nil when unknown.
function MapLayout:get_map(id)
  return self.maps[id]
end

--- Returns resolved neighbors in their declared order without allocating another list.
--- An existing map with no declared neighbors returns an empty list.
---@param id string Source map identifier.
---@return MapRegion[]|nil neighbors Read-only region list, or nil for an unknown source map.
function MapLayout:get_neighbors(id)
  return self.neighbors_by_map[id]
end

--- Finds the map containing a global XY position without changing runtime state.
--- Z remains independent; this initial layout does not support overlapping XY regions.
--- Does not load maps, wrap coordinates, move entities or constrain movement.
---@param x number Global world X.
---@param y number Global world Y.
---@return MapRegion|nil map Read-only region, or nil outside all maps.
function MapLayout:find_map(x, y)
  assert(type(x) == "number" and x > -math.huge and x < math.huge
    and type(y) == "number" and y > -math.huge and y < math.huge,
    "map lookup coordinates must be finite")

  for _, map in ipairs(self.ordered_maps) do
    if contains(map, x, y) then return map end
  end
end

return MapLayout
