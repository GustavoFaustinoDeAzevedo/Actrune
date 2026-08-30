local RotationResponse = require("engine.render.camera_rotation.rotation_response")

local CameraRotationControl = {}
CameraRotationControl.__index = CameraRotationControl

-- Creates a control that resolves and applies camera rotation through configurable policies.
function CameraRotationControl.new(camera, policy, options)
  options = options or {}

  assert(camera ~= nil, "camera rotation control requires a camera")
  assert(type(camera.get_rotation) == "function" and type(camera.set_rotation) == "function",
    "camera rotation control requires rotation accessors")
  assert(policy ~= nil and type(policy.resolve) == "function", "camera rotation control requires a resolvable policy")

  local self = setmetatable({}, CameraRotationControl)
  self.camera = camera
  self.policy = policy
  self.response = options.response or RotationResponse.new()

  assert(type(self.response.resolve) == "function", "camera rotation control response must be resolvable")

  return self
end

-- Resolves the target rotation and approaches it through the configured response.
function CameraRotationControl:update(dt, context)
  local target = self.policy:resolve({
    camera = self.camera,
    dt = dt,
    context = context
  })

  assert(type(target) == "number", "camera rotation policy must resolve a numeric rotation")

  local rotation = self.response:resolve(self.camera:get_rotation(), target, dt)
  assert(type(rotation) == "number", "camera rotation response must resolve a numeric rotation")

  self.camera:set_rotation(rotation)
end

return CameraRotationControl
