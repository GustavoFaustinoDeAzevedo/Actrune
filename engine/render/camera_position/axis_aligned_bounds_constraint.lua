---@class AxisAlignedBoundsConstraint: AxisAlignedBoundsConstraintFields
local AxisAlignedBoundsConstraint = {}
AxisAlignedBoundsConstraint.__index = AxisAlignedBoundsConstraint

--- Validates finite bounds before changing any runtime state.
---@param bounds CameraBounds Complete world-space rectangle.
local function validate_bounds(bounds)
  assert(type(bounds) == "table", "camera bounds require a table")
  for _, name in ipairs({ "min_x", "min_y", "max_x", "max_y" }) do
    local value = bounds[name]
    assert(type(value) == "number" and value > -math.huge and value < math.huge,
      "camera bounds " .. name .. " must be finite")
  end
  assert(bounds.max_x >= bounds.min_x, "camera bounds max_x must be at least min_x")
  assert(bounds.max_y >= bounds.min_y, "camera bounds max_y must be at least min_y")
end

--- Copies numeric bounds into an existing rectangle without retaining the source.
---@param destination CameraBounds Rectangle receiving the coordinates.
---@param source CameraBounds Rectangle providing the coordinates.
local function copy_bounds(destination, source)
  destination.min_x, destination.min_y = source.min_x, source.min_y
  destination.max_x, destination.max_y = source.max_x, source.max_y
end

--- Creates initial bounds without a transition; each camera owns its constraint.
---@param options AxisAlignedBoundsConstraintOptions Bounds and fixed axis settings.
---@return AxisAlignedBoundsConstraint constraint Stateful camera position constraint.
function AxisAlignedBoundsConstraint.new(options)
  validate_bounds(options)
  assert(options.constrain_x == nil or type(options.constrain_x) == "boolean",
    "camera constrain_x must be boolean")
  assert(options.constrain_y == nil or type(options.constrain_y) == "boolean",
    "camera constrain_y must be boolean")

  local self = setmetatable({
    constrain_x = options.constrain_x ~= false,
    constrain_y = options.constrain_y ~= false,
    start_bounds = { min_x = 0, min_y = 0, max_x = 0, max_y = 0 },
    target_bounds = { min_x = 0, min_y = 0, max_x = 0, max_y = 0 },
    duration = 0,
    elapsed = 0
  }, AxisAlignedBoundsConstraint)
  copy_bounds(self, options)
  copy_bounds(self.start_bounds, options)
  copy_bounds(self.target_bounds, options)
  return self
end

--- Selects bounds immediately or transitions from the currently interpolated rectangle.
--- Repeating the same timed destination does not restart or change its duration.
--- Zero duration always applies the destination, including an unfinished transition.
--- Copies coordinates only; axis settings are preserved. The camera moves on resolve.
---@param bounds CameraBounds Complete destination rectangle.
---@param duration? number Finite seconds; nil or zero applies bounds immediately.
function AxisAlignedBoundsConstraint:set_bounds(bounds, duration)
  validate_bounds(bounds)
  if duration == nil then duration = 0 end
  assert(type(duration) == "number" and duration >= 0 and duration < math.huge,
    "camera bounds duration must be finite and non-negative")

  local target = self.target_bounds
  if duration > 0 and bounds.min_x == target.min_x and bounds.min_y == target.min_y
      and bounds.max_x == target.max_x and bounds.max_y == target.max_y then
    return
  end

  copy_bounds(self.start_bounds, self)
  copy_bounds(target, bounds)
  self.duration, self.elapsed = duration, 0
  if duration == 0 then copy_bounds(self, target) end
end

--- Returns the effective rectangle without advancing time or allocating a table.
---@return number min_x Left boundary.
---@return number min_y Upper boundary.
---@return number max_x Right boundary.
---@return number max_y Lower boundary.
function AxisAlignedBoundsConstraint:get_bounds()
  return self.min_x, self.min_y, self.max_x, self.max_y
end

--- Reports whether the selected timed transition still has time remaining.
---@return boolean transitioning Whether subsequent resolves can advance the bounds.
function AxisAlignedBoundsConstraint:is_transitioning()
  return self.elapsed < self.duration
end

--- Advances bounds with smoothstep easing; interruption preserves position, not velocity.
---@param self AxisAlignedBoundsConstraint Constraint owning the transition.
---@param dt number Finite non-negative elapsed seconds.
local function advance_bounds(self, dt)
  if dt == 0 or not self:is_transitioning() then return end
  self.elapsed = math.min(self.elapsed + dt, self.duration)
  if self.elapsed == self.duration then
    copy_bounds(self, self.target_bounds)
    return
  end

  local progress = self.elapsed / self.duration
  local weight = progress * progress * (3 - 2 * progress)
  local remaining = 1 - weight
  local start, target = self.start_bounds, self.target_bounds
  self.min_x = remaining * start.min_x + weight * target.min_x
  self.min_y = remaining * start.min_y + weight * target.min_y
  self.max_x = remaining * start.max_x + weight * target.max_x
  self.max_y = remaining * start.max_y + weight * target.max_y
end

--- Resolves world-axis half extents of the current rotated viewport.
---@param camera table Camera exposing get_viewport, get_zoom and get_rotation.
---@return number half_x Horizontal half extent in world units.
---@return number half_y Vertical half extent in world units.
local function resolve_view_half_extents(camera)
  local _, _, viewport_width, viewport_height = camera:get_viewport()
  local zoom = camera:get_zoom()
  local half_width = viewport_width * 0.5 / zoom
  local half_height = viewport_height * 0.5 / zoom
  local rotation = camera:get_rotation()
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

--- Advances the transition once, then constrains the requested camera position.
--- CameraPositionControl supplies dt; omitting it or using zero only samples bounds.
--- Use this constraint once per camera update to avoid advancing time twice.
--- The interpolated rectangle may expose space between the source and destination.
---@param x number Requested camera X after position smoothing.
---@param y number Requested camera Y after position smoothing.
---@param context CameraBoundsResolveContext Camera geometry and optional elapsed time.
---@return number x Resolved camera X.
---@return number y Resolved camera Y.
function AxisAlignedBoundsConstraint:resolve(x, y, context)
  local camera = context and context.camera
  assert(camera ~= nil, "camera bounds constraint requires context.camera")
  local dt = context.dt
  if dt == nil then dt = 0 end
  assert(type(dt) == "number" and dt >= 0 and dt < math.huge,
    "camera bounds dt must be finite and non-negative")

  advance_bounds(self, dt)
  local half_x, half_y = resolve_view_half_extents(camera)
  if self.constrain_x then x = constrain_axis(x, self.min_x, self.max_x, half_x) end
  if self.constrain_y then y = constrain_axis(y, self.min_y, self.max_y, half_y) end
  return x, y
end

return AxisAlignedBoundsConstraint
