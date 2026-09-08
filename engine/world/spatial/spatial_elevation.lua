---@class SpatialElevation: SpatialElevationFields
local SpatialElevation = {}
SpatialElevation.__index = SpatialElevation

--- Creates vertical placement using a shared level mapping.
--- The initial level must exist, and the offset must be finite.
---@param options SpatialElevationOptions Initial vertical placement.
---@return SpatialElevation elevation New elevation component.
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

--- Returns the shared level mapping without copying it.
---@return SpatialLevels levels Mapping used by this component.
function SpatialElevation:get_levels()
  return self.levels
end

--- Returns the reference level index, not the absolute height.
---@return integer level Current zero-based reference level.
function SpatialElevation:get_level()
  return self.level
end

--- Returns vertical displacement relative to the reference level.
--- Positive values are above the level; negative values are below it.
---@return number offset Signed displacement in world units.
function SpatialElevation:get_offset()
  return self.offset
end

--- Returns absolute Z: reference level elevation plus local offset.
--- Does not change the entity's planar X and Y coordinates.
---@return number z Absolute elevation in world units.
function SpatialElevation:get_elevation()
  return self.levels:get_elevation(self.level) + self.offset
end

--- Assigns the reference level and offset together after validating both.
--- Does not check collisions or preserve the previous absolute Z.
--- Use ElevationMover when movement must respect obstacles.
---@param level integer Existing zero-based reference level.
---@param offset number Finite displacement relative to the selected level.
function SpatialElevation:set_position(level, offset)
  assert(type(offset) == "number"
    and offset > -math.huge and offset < math.huge,
    "spatial elevation offset must be finite")

  -- Validate the destination before changing either part of the current position.
  self.levels:get_elevation(level)

  self.level = level
  self.offset = offset
end

--- Changes the offset while preserving the reference level.
--- Does not check collisions or automatically select another level.
---@param offset number Finite displacement relative to the current level.
function SpatialElevation:set_offset(offset)
  self:set_position(self.level, offset)
end

return SpatialElevation
