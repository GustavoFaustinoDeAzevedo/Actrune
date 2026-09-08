---@class SpatialLevels: SpatialLevelsFields
local SpatialLevels = {}
SpatialLevels.__index = SpatialLevels

--- Creates a level mapping by copying a non-empty sequence of elevations.
--- Values must be finite and strictly increasing.
--- Array index 1 represents level 0, index 2 represents level 1, and so on.
---@param elevations number[] Absolute Z values in world units.
---@return SpatialLevels levels New level mapping.
function SpatialLevels.new(elevations)
  assert(type(elevations) == "table" and #elevations > 0,
    "spatial levels require a non-empty elevation sequence")

  local values = {}

  for index = 1, #elevations do
    local elevation = elevations[index]

    assert(type(elevation) == "number"
      and elevation > -math.huge and elevation < math.huge,
      "spatial level elevation must be finite")

    assert(index == 1 or elevation > values[index - 1],
      "spatial level elevations must be strictly increasing")

    values[index] = elevation
  end

  return setmetatable({
    elevations = values
  }, SpatialLevels)
end

--- Returns how many levels this mapping contains.
---@return integer count Number of available levels.
function SpatialLevels:get_count()
  return #self.elevations
end

--- Returns the absolute Z assigned to a level.
--- Raises an error when the index is not an integer or is outside this mapping.
---@param level integer Zero-based index, from 0 to get_count() - 1.
---@return number z Absolute level elevation in world units.
function SpatialLevels:get_elevation(level)
  assert(type(level) == "number" and level % 1 == 0,
    "spatial level must be an integer")
  assert(level >= 0 and level < #self.elevations,
    "spatial level is out of range")

  return self.elevations[level + 1]
end

return SpatialLevels
