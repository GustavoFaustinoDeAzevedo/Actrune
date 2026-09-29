local PositionResponse = require("engine.render.camera_position.position_response")

---@class CameraPositionControl: CameraPositionControlFields
local CameraPositionControl = {}
CameraPositionControl.__index = CameraPositionControl

--- Creates camera tracking with optional periodic target selection.
--- Periodicity is applied after the complete position policy and before smoothing.
---@param camera table Camera exposing get_position and set_position.
---@param policy table Position policy exposing resolve.
---@param options? CameraPositionControlOptions Response, constraints and map topology.
---@return CameraPositionControl control New camera position control.
function CameraPositionControl.new(camera, policy, options)
  options = options or {}

  assert(camera ~= nil, "camera position control requires a camera")
  assert(policy ~= nil and type(policy.resolve) == "function",
    "camera position control requires a resolvable policy")
  assert(options.topology == nil or type(options.topology.get_nearest_position) == "function",
    "camera position control topology must expose get_nearest_position")

  local self = setmetatable({}, CameraPositionControl)

  self.camera = camera
  self.policy = policy
  self.response = options.response or PositionResponse.new()
  self.constraints = options.constraints or {}
  self.topology = options.topology

  assert(type(self.response.resolve) == "function", "camera position control response must be resolvable")
  assert(type(self.constraints) == "table", "camera position control constraints must be a table")

  for _, constraint in ipairs(self.constraints) do
    assert(constraint ~= nil and type(constraint.resolve) == "function",
      "camera position constraints must be resolvable")
  end

  return self
end

--- Resolves the complete target, its nearest image, smoothing and final constraints.
--- Periodic following assumes final target-camera separation below half a period.
--- Large teleports require explicitly repositioning the camera.
---@param dt number Elapsed time in seconds.
---@param context? any Additional context forwarded to policies and constraints.
function CameraPositionControl:update(dt, context)
  local resolve_context = {
    camera = self.camera,
    dt = dt,
    context = context
  }

  local target_x, target_y = self.policy:resolve(resolve_context)

  assert(type(target_x) == "number" and type(target_y) == "number",
    "camera position policy must resolve numeric coordinates")

  local current_x, current_y = self.camera:get_position()

  if self.topology ~= nil then
    target_x, target_y = self.topology:get_nearest_position(
      target_x, target_y, current_x, current_y
    )
  end

  local x, y = self.response:resolve(current_x, current_y, target_x, target_y, dt)

  for _, constraint in ipairs(self.constraints) do
    x, y = constraint:resolve(x, y, resolve_context)
  end

  assert(type(x) == "number" and type(y) == "number", "camera position control must resolve numeric coordinates")
  self.camera:set_position(x, y)
end

--- Resolves the complete target and samples constraints without moving the camera.
--- Bypasses position smoothing; automatic constraints may synchronize their destination.
---@param context? any Additional context forwarded to policies and constraints.
---@return number x Constrained target X.
---@return number y Constrained target Y.
function CameraPositionControl:resolve_target(context)
  local resolve_context = { camera = self.camera, dt = 0, context = context }
  local x, y = self.policy:resolve(resolve_context)
  if self.topology ~= nil then
    local current_x, current_y = self.camera:get_position()
    x, y = self.topology:get_nearest_position(x, y, current_x, current_y)
  end
  for _, constraint in ipairs(self.constraints) do
    x, y = constraint:resolve(x, y, resolve_context)
  end
  assert(type(x) == "number" and x > -math.huge and x < math.huge
    and type(y) == "number" and y > -math.huge and y < math.huge,
    "camera position control must resolve finite coordinates")
  return x, y
end

--- Applies the constrained target immediately, bypassing position smoothing.
---@param context? any Additional context forwarded to policies and constraints.
function CameraPositionControl:snap(context)
  self.camera:set_position(self:resolve_target(context))
end

return CameraPositionControl
