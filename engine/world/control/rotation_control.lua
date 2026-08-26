local Rotation = require("engine.world.movement.rotation.rotation")

local RotationControl = {}
RotationControl.__index = RotationControl

-- Creates a control-driven rotation configuration.
function RotationControl.new(options)
  options = options or {}

  local self = setmetatable({}, RotationControl)

  self.controls = options.controls or "controls"
  self.input = options.input
  self.amount = options.amount
  self.application = options.application

  self.entity = nil
  self.control_profile = nil
  self.rotation = nil

  assert(type(self.input) == "string", "rotation control input must be a string")
  assert(self.amount ~= nil and type(self.amount.resolve) == "function",
    "rotation control amount must be a resolvable value")
  assert(self.application ~= nil and type(self.application.should_apply) == "function",
    "rotation control application must be a control application policy")

  return self
end

-- Binds the rotation control to its entity transform.
function RotationControl:bind_control(world, entity)
  assert(entity ~= nil, "rotation control requires an entity")

  self.entity = entity
  self.control_profile = entity:get_component(self.controls)

  assert(self.control_profile ~= nil, "rotation control references missing controls component: " .. self.controls)

  self.rotation = Rotation.new(entity.transform)
end

-- Resolves control intent and applies rotation according to its independent policies.
function RotationControl:update_control(runtime, dt)
  assert(self.rotation ~= nil, "rotation control is not bound")

  local direction = self.control_profile:resolve_axis(self.input, runtime)
  local active = direction ~= 0

  if not self.application:should_apply({
        active = active,
        dt = dt,
        entity = self.entity,
        runtime = runtime
      }) then
    return
  end

  local amount = self.amount:resolve({
    dt = dt,
    entity = self.entity,
    runtime = runtime
  })

  self.rotation:turn(direction * amount)
end

return RotationControl
