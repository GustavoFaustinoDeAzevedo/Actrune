local SpatialActionControl = {}
SpatialActionControl.__index = SpatialActionControl

-- Creates a control-driven spatial action configuration.
function SpatialActionControl.new(options)
  options = options or {}

  local self = setmetatable({}, SpatialActionControl)

  self.controls = options.controls or "controls"
  self.input = options.input

  self.entity = nil
  self.control_profile = nil

  assert(type(self.input) == "string", "spatial action control input must be a string")

  return self
end

-- Binds the spatial action control to its entity and control profile.
function SpatialActionControl:bind_control(world, entity)
  assert(entity ~= nil, "spatial action control requires an entity")

  self.entity = entity
  self.control_profile = entity:get_component(self.controls)

  assert(self.control_profile ~= nil, "spatial action control references missing controls component: " .. self.controls)
end

-- Resolves the configured logical action and triggers its spatial action when pressed.
function SpatialActionControl:update_control(runtime, dt)
  assert(self.entity ~= nil, "spatial action control is not bound")

  local action = self.control_profile:get_action(self.input)

  if runtime:is_action_pressed(action) then
    runtime:trigger_spatial_action(action, self.entity)
  end
end

return SpatialActionControl
