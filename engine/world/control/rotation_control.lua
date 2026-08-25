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

  self.control_profile = nil
  self.rotation = nil
  self.entity = nil

  assert(type(self.input) == "string", "rotation control input must be a string")
  assert(self.amount ~= nil and type(self.amount.resolve) == "function",
    "rotation control amount must be a resolvable value")

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

-- Resolves control intent and the configured rotation amount.
function RotationControl:update_control(runtime, dt)
  assert(self.rotation ~= nil, "rotation control is not bound")

  local direction = self.control_profile:resolve_axis(self.input, runtime)
  local amount = self.amount:resolve({ dt = dt, entity = self.entity, runtime = runtime })

  self.rotation:turn(direction * amount)
end

return RotationControl
