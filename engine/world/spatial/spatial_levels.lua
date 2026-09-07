local SpatialLevels = {}
SpatialLevels.__index = SpatialLevels

-- Creates an ordered mapping from zero-based levels to world-space elevations.
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

-- Returns the number of levels defined by this mapping.
function SpatialLevels:get_count()
  return #self.elevations
end

-- Returns the elevation associated with one zero-based level.
function SpatialLevels:get_elevation(level)
  assert(type(level) == "number" and level % 1 == 0,
    "spatial level must be an integer")
  assert(level >= 0 and level < #self.elevations,
    "spatial level is out of range")

  return self.elevations[level + 1]
end

return SpatialLevels
