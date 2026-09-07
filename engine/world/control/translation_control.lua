local Translation = require("engine.world.movement.translation.translation")
local SpatialMover = require("engine.world.spatial.spatial_mover")
local VerticalRangeFilter = require("engine.world.spatial.vertical_range_filter")

local TranslationControl = {}
TranslationControl.__index = TranslationControl

-- Creates a control-driven translation configuration.
function TranslationControl.new(options)
  options = options or {}

  local self = setmetatable({}, TranslationControl)

  self.controls = options.controls or "controls"
  self.input = options.input
  self.direction = options.direction
  self.direction_policy = options.direction_policy
  self.displacement = options.displacement
  self.application = options.application
  self.source_shape = options.source_shape
  self.target_shape = options.target_shape
  self.source_vertical_range = options.source_vertical_range
  self.target_vertical_range = options.target_vertical_range

  assert((self.source_vertical_range == nil) == (self.target_vertical_range == nil),
    "translation control requires both vertical range names or neither")

  if self.source_vertical_range ~= nil then
    assert(type(self.source_vertical_range) == "string" and self.source_vertical_range ~= "",
      "translation control source vertical range must be a non-empty name")
    assert(type(self.target_vertical_range) == "string" and self.target_vertical_range ~= "",
      "translation control target vertical range must be a non-empty name")
  end

  self.entity = nil
  self.control_profile = nil
  self.direction_resolver = nil
  self.translation = nil

  assert(type(self.input) == "string", "translation control input must be a string")
  assert(type(self.direction) == "string", "translation control direction must be a component name")
  assert(self.direction_policy ~= nil and type(self.direction_policy.resolve) == "function",
    "translation control direction policy must be resolvable")
  assert(self.displacement ~= nil and type(self.displacement.resolve) == "function",
    "translation control displacement must be resolvable")
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

  local target_filter = nil

  if self.source_vertical_range ~= nil then
    target_filter = VerticalRangeFilter.create(
      entity,
      self.source_vertical_range,
      self.target_vertical_range
    )
  end

  local mover = SpatialMover.new(world, entity, {
    source_shape = self.source_shape,
    target_shape = self.target_shape,
    target_filter = target_filter
  })

  self.translation = Translation.new(mover)
end

-- Resolves control intent and applies the configured direction, displacement, and application policies.
function TranslationControl:update_control(runtime, dt)
  assert(self.entity ~= nil, "translation control is not bound")

  local input_x, input_y = self.control_profile:resolve_vector(self.input, runtime)
  input_x, input_y = self.direction_policy:resolve(input_x, input_y)

  local active = input_x ~= 0 or input_y ~= 0

  local context = {
    active = active,
    dt = dt,
    entity = self.entity,
    runtime = runtime,
    input_x = input_x,
    input_y = input_y
  }

  if not self.application:should_apply(context) then return end

  local direction_x, direction_y = self.direction_resolver:resolve(input_x, input_y, self.entity.transform)
  local movement_x, movement_y = self.displacement:resolve(direction_x, direction_y, context)

  self.translation:move(movement_x, movement_y)
end

return TranslationControl
