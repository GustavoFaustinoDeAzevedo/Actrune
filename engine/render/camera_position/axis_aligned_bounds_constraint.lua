---@class AxisAlignedBoundsConstraint: CameraBounds
local AxisAlignedBoundsConstraint = {}
AxisAlignedBoundsConstraint.__index = AxisAlignedBoundsConstraint

--- Creates a fixed rectangle that constrains the orthographic camera's visible area.
--- Bounds use world coordinates and must be finite and ordered.
---@param options CameraBounds Rectangle containing the intended visible area.
---@return AxisAlignedBoundsConstraint constraint New camera position constraint.
function AxisAlignedBoundsConstraint.new(options)
  assert(type(options) == "table", "camera bounds require options")

  for _, name in ipairs({ "min_x", "min_y", "max_x", "max_y" }) do
    local value = options[name]
    assert(type(value) == "number" and value > -math.huge and value < math.huge,
      "camera bounds " .. name .. " must be finite")
  end

  assert(options.max_x >= options.min_x,
    "camera bounds max_x must be greater than or equal to min_x")
  assert(options.max_y >= options.min_y,
    "camera bounds max_y must be greater than or equal to min_y")

  return setmetatable({
    min_x = options.min_x,
    min_y = options.min_y,
    max_x = options.max_x,
    max_y = options.max_y
  }, AxisAlignedBoundsConstraint)
end

--- Resolves world-axis half extents of the current rotated viewport.
---@param camera table Camera exposing get_viewport, get_zoom and get_rotation.
---@return number half_x Horizontal half extent in world units.
---@return number half_y Vertical half extent in world units.
local function resolve_view_half_extents(camera)
  local _, _, viewport_width, viewport_height = camera:get_viewport()
  local zoom = camera:get_zoom()
  local rotation = camera:get_rotation()
  local half_width = viewport_width * 0.5 / zoom
  local half_height = viewport_height * 0.5 / zoom
  local cos_rotation = math.abs(math.cos(rotation))
  local sin_rotation = math.abs(math.sin(rotation))

  return half_width * cos_rotation + half_height * sin_rotation,
      half_width * sin_rotation + half_height * cos_rotation
end

--- Clamps one camera axis, or centers it when the visible area cannot fit.
---@param value number Requested camera center.
---@param minimum number Lower scene bound.
---@param maximum number Upper scene bound.
---@param half_extent number Visible half extent on this axis.
---@return number position Constrained camera center.
local function constrain_axis(value, minimum, maximum, half_extent)
  local minimum_center = minimum + half_extent
  local maximum_center = maximum - half_extent

  if minimum_center > maximum_center then return (minimum + maximum) * 0.5 end

  return math.max(minimum_center, math.min(maximum_center, value))
end

--- Constrains the visible viewport after position smoothing.
--- Centers axes where the viewport is larger than the scene; exterior space remains visible.
--- Does not constrain entities, perform collision queries or change camera zoom.
---@param x number Requested camera X in world units.
---@param y number Requested camera Y in world units.
---@param context { camera: table } Camera used to calculate the current visible extents.
---@return number x Constrained camera X.
---@return number y Constrained camera Y.
function AxisAlignedBoundsConstraint:resolve(x, y, context)
  local camera = context and context.camera
  assert(camera ~= nil, "camera bounds constraint requires context.camera")

  local half_x, half_y = resolve_view_half_extents(camera)

  return constrain_axis(x, self.min_x, self.max_x, half_x),
      constrain_axis(y, self.min_y, self.max_y, half_y)
end

return AxisAlignedBoundsConstraint
