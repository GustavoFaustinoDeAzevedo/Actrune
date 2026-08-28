local CameraPositionControl = {}
CameraPositionControl.__index = CameraPositionControl

-- Creates a control that updates a camera position through a resolvable policy.
function CameraPositionControl.new(camera, policy)
  assert(camera ~= nil, "camera position control requires a camera")
  assert(policy ~= nil and type(policy.resolve) == "function", "camera position control requires a resolvable policy")

  return setmetatable({
    camera = camera,
    policy = policy
  }, CameraPositionControl)
end

-- Resolves and applies the camera position for the current update.
function CameraPositionControl:update(dt, context)
  local x, y = self.policy:resolve({
    camera = self.camera,
    dt = dt,
    context = context
  })

  assert(type(x) == "number" and type(y) == "number", "camera position policy must resolve numeric coordinates")

  self.camera:set_position(x, y)
end

return CameraPositionControl
