local ElevationMover = require("engine.world.spatial.elevation_mover")

local ElevationControl = {}
ElevationControl.__index = ElevationControl

-- Creates vertical input using the existing amount and application policies.
function ElevationControl.new(options)
  assert(type(options) == "table", "elevation control requires options")
  assert(type(options.input) == "string", "elevation control requires an input name")
  assert(options.amount ~= nil and type(options.amount.resolve) == "function",
    "elevation control requires a resolvable amount")
  assert(options.application ~= nil and type(options.application.should_apply) == "function",
    "elevation control requires an application policy")

  return setmetatable({
    controls = options.controls or "controls",
    input = options.input,
    amount = options.amount,
    application = options.application,
    movement = {
      elevation_component = options.elevation_component,
      source_shape = options.source_shape,
      target_shape = options.target_shape,
      source_vertical_range = options.source_vertical_range,
      target_vertical_range = options.target_vertical_range
    }
  }, ElevationControl)
end

-- Resolves entity dependencies once when the control system binds this component.
function ElevationControl:bind_control(world, entity)
  self.control_profile = entity:get_component(self.controls)
  assert(self.control_profile ~= nil and type(self.control_profile.resolve_axis) == "function",
    "elevation control references invalid controls component: " .. self.controls)

  self.mover = ElevationMover.new(world, entity, self.movement)
  self.entity = entity
end

-- Applies vertical intent while letting inactive input reset stateful policies.
function ElevationControl:update_control(runtime, dt)
  assert(self.mover ~= nil, "elevation control is not bound")

  local direction = self.control_profile:resolve_axis(self.input, runtime)
  local context = {
    active = direction ~= 0,
    direction = direction,
    dt = dt,
    entity = self.entity,
    runtime = runtime
  }

  if not self.application:should_apply(context) or direction == 0 then return end

  return self.mover:try_move(direction * self.amount:resolve(context))
end

return ElevationControl
