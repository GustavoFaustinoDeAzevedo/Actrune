local AxisAlignedBoundsConstraint = {}
AxisAlignedBoundsConstraint.__index = AxisAlignedBoundsConstraint

-- Creates a camera position constraint that keeps its visible viewport inside world bounds.
function AxisAlignedBoundsConstraint.new(options)
  options = options or {}

  local self = setmetatable({}, AxisAlignedBoundsConstraint)

  self.min_x = options.min_x
  self.min_y = options.min_y
  self.max_x = options.max_x
  self.max_y = options.max_y

  assert(type(self.min_x) == "number", "camera bounds min_x must be a number")
  assert(type(self.min_y) == "number", "camera bounds min_y must be a number")
  assert(type(self.max_x) == "number", "camera bounds max_x must be a number")
  assert(type(self.max_y) == "number", "camera bounds max_y must be a number")
  assert(self.max_x >= self.min_x, "camera bounds max_x must be greater than or equal to min_x")
  assert(self.max_y >= self.min_y, "camera bounds max_y must be greater than or equal to min_y")

  return self
end

-- Resolves the world-space half extents occupied by the camera viewport.
local function resolve_view_half_extents(camera)
  local _, _, viewport_width, viewport_height = camera:get_viewport()
  local half_width = viewport_width * 0.5 / camera.zoom
  local half_height = viewport_height * 0.5 / camera.zoom
  local cos_rotation = math.abs(math.cos(camera.rotation))
  local sin_rotation = math.abs(math.sin(camera.rotation))

  local half_x = half_width * cos_rotation + half_height * sin_rotation
  local half_y = half_width * sin_rotation + half_height * cos_rotation

  return half_x, half_y
end

-- Constrains one axis while centering it when the available area is smaller than the viewport.
local function constrain_axis(value, minimum, maximum, half_extent)
  local minimum_center = minimum + half_extent
  local maximum_center = maximum - half_extent

  if minimum_center > maximum_center then return (minimum + maximum) * 0.5 end

  return math.max(minimum_center, math.min(maximum_center, value))
end

-- Keeps the complete visible camera viewport inside the configured world bounds.
function AxisAlignedBoundsConstraint:resolve(x, y, context)
  local camera = context and context.camera
  assert(camera ~= nil, "camera bounds constraint requires context.camera")

  local half_x, half_y = resolve_view_half_extents(camera)

  return constrain_axis(x, self.min_x, self.max_x, half_x),
      constrain_axis(y, self.min_y, self.max_y, half_y)
end

return AxisAlignedBoundsConstraint
