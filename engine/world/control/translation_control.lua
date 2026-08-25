local Velocity = require("engine.world.movement.velocity")
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
  self.speed = options.speed or 0
  self.source_shape = options.source_shape
  self.target_shape = options.target_shape

  self.entity = nil
  self.control_profile = nil
  self.direction_resolver = nil
  self.velocity = nil
  self.translation = nil

  assert(type(self.input) == "string", "translation control input must be a string")
  assert(type(self.direction) == "string", "translation control direction must be a component name")
  assert(type(self.speed) == "number", "translation control speed must be a number")

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

  self.velocity = Velocity.new()
  self.translation = Translation.new(mover)
end

-- Resolves control intent and translates the bound entity.
function TranslationControl:update_control(runtime, dt)
  assert(self.entity ~= nil, "translation control is not bound")

  local input_x, input_y = self.control_profile:resolve_vector(self.input, runtime)
  local direction_x, direction_y = self.direction_resolver:resolve(input_x, input_y, self.entity.transform)

  self.velocity:set(direction_x * self.speed, direction_y * self.speed)

  local movement_x, movement_y = self.velocity:get_displacement(dt)
  self.translation:move(movement_x, movement_y)
end

return TranslationControl
