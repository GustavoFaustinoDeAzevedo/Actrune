local SpatialElevation = {}
SpatialElevation.__index = SpatialElevation

-- Creates independent vertical placement backed by a shared level mapping.
function SpatialElevation.new(options)
  options = options or {}

  assert(options.levels ~= nil and type(options.levels.get_elevation) == "function",
    "spatial elevation requires levels exposing get_elevation")

  local self = setmetatable({
    levels = options.levels
  }, SpatialElevation)

  self:set_position(options.level or 0, options.offset or 0)

  return self
end

-- Returns the level mapping used by this component.
function SpatialElevation:get_levels()
  return self.levels
end

-- Returns the current zero-based reference level.
function SpatialElevation:get_level()
  return self.level
end

-- Returns the vertical displacement relative to the reference level.
function SpatialElevation:get_offset()
  return self.offset
end

-- Returns the absolute world-space elevation.
function SpatialElevation:get_elevation()
  return self.levels:get_elevation(self.level) + self.offset
end

-- Changes the reference level and its local offset together.
function SpatialElevation:set_position(level, offset)
  assert(type(offset) == "number"
    and offset > -math.huge and offset < math.huge,
    "spatial elevation offset must be finite")

  -- Validate the destination before changing either part of the current position.
  self.levels:get_elevation(level)

  self.level = level
  self.offset = offset
end

-- Changes vertical displacement while preserving the reference level.
function SpatialElevation:set_offset(offset)
  self:set_position(self.level, offset)
end

return SpatialElevation
