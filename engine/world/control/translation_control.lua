local Translation = require("engine.world.movement.translation.translation")
local SpatialMover = require("engine.world.spatial.spatial_mover")

local TranslationControl = {}
TranslationControl.__index = TranslationControl

-- Creates a control-driven translation configuration.
function TranslationControl.new(options)
  options = options or {}

  local self = setmetatable({}, TranslationControl)

  self.controls = options.controls or "controls"
  self.input = options.input
  self.direction = options.direction
  self.amount = options.amount
  self.application = options.application
  self.source_shape = options.source_shape
  self.target_shape = options.target_shape

  self.entity = nil
  self.control_profile = nil
  self.direction_resolver = nil
  self.translation = nil

  assert(type(self.input) == "string", "translation control input must be a string")
  assert(type(self.direction) == "string", "translation control direction must be a component name")
  assert(self.amount ~= nil and type(self.amount.resolve) == "function",
    "translation control amount must be a resolvable value")
  assert(self.application ~= nil and type(self.application.should_apply) == "function",
    "translation control application must be a control application policy")

  return self
end

-- Binds the translation control to its entity and spatial world.
function TranslationControl:bind_control(world, entity)
  assert(world ~= nil, "translation control requires a world")
  assert(entity ~= nil, "translation control requires an entity")

  self.entity = entity
  self.control_profile = entity:get_component(self.controls)
  self.direction_resolver = entity:get_component(self.direction)

  assert(self.control_profile ~= nil, "translation control references missing controls component: " .. self.controls)
  assert(self.direction_resolver ~= nil, "translation control references missing direction component: " .. self
  .direction)

  local mover = SpatialMover.new(world, entity, {
    source_shape = self.source_shape,
    target_shape = self.target_shape
  })

  self.translation = Translation.new(mover)
end

-- Resolves control intent and applies translation according to its independent policies.
function TranslationControl:update_control(runtime, dt)
  assert(self.entity ~= nil, "translation control is not bound")

  local input_x, input_y = self.control_profile:resolve_vector(self.input, runtime)
  local active = input_x ~= 0 or input_y ~= 0

  if not self.application:should_apply({
        active = active,
        dt = dt,
        entity = self.entity,
        runtime = runtime
      }) then
    return
  end

  local direction_x, direction_y = self.direction_resolver:resolve(input_x, input_y, self.entity.transform)
  local amount = self.amount:resolve({
    dt = dt,
    entity = self.entity,
    runtime = runtime
  })

  self.translation:move(direction_x * amount, direction_y * amount)
end

return TranslationControl
