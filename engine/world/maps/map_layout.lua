---@class MapLayout: MapLayoutFields
local MapLayout = {}
MapLayout.__index = MapLayout

--- Tests map membership using half-open bounds.
--- A shared edge belongs to the map beginning at that edge.
---@param map MapRegion Region being tested.
---@param x number Global world X.
---@param y number Global world Y.
---@return boolean inside Whether the point belongs to the region.
local function contains(map, x, y)
  return x >= map.min_x and x < map.max_x and y >= map.min_y and y < map.max_y
end

--- Creates non-overlapping map regions in one continuous world coordinate space.
--- Copies definitions once; returned regions must be treated as read-only.
---@param definitions table<string, MapRegionDefinition> Bounds indexed by map identifier.
---@return MapLayout layout Resident map layout.
function MapLayout.new(definitions)
  assert(type(definitions) == "table" and next(definitions) ~= nil,
    "map layout requires at least one map")

  local self = setmetatable({ maps = {}, ordered_maps = {} }, MapLayout)

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
      max_y = definition.max_y
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
  return self
end

--- Returns the resident region definition associated with an identifier.
---@param id string Map identifier.
---@return MapRegion|nil map Read-only region, or nil when unknown.
function MapLayout:get_map(id)
  return self.maps[id]
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
