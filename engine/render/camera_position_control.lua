local PositionResponse = require("engine.render.camera_position.position_response")

local CameraPositionControl = {}
CameraPositionControl.__index = CameraPositionControl

-- Creates a control that resolves and applies a camera position through configurable policies.
function CameraPositionControl.new(camera, policy, options)
  options = options or {}

  assert(camera ~= nil, "camera position control requires a camera")
  assert(policy ~= nil and type(policy.resolve) == "function", "camera position control requires a resolvable policy")

  local self = setmetatable({}, CameraPositionControl)

  self.camera = camera
  self.policy = policy
  self.response = options.response or PositionResponse.new()
  self.constraints = options.constraints or {}

  assert(type(self.response.resolve) == "function", "camera position control response must be resolvable")
  assert(type(self.constraints) == "table", "camera position control constraints must be a table")

  for _, constraint in ipairs(self.constraints) do
    assert(constraint ~= nil and type(constraint.resolve) == "function", "camera position constraints must be resolvable")
  end

  return self
end

-- Resolves the target, response, and configured position constraints for the current update.
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
  local x, y = self.response:resolve(current_x, current_y, target_x, target_y, dt)

  for _, constraint in ipairs(self.constraints) do
    x, y = constraint:resolve(x, y, resolve_context)
  end

  assert(type(x) == "number" and type(y) == "number", "camera position control must resolve numeric coordinates")

  self.camera:set_position(x, y)
end

return CameraPositionControl
