local ActionAxis = require("engine.core.actions.action_axis")
local ActionActivation = require("engine.core.actions.actions_activation")
local ActionVector = require("engine.core.actions.action_vector")
local ControlProfile = require("engine.world.control.control_profile")

local ControlProfileFactory = {}

-- Creates one runtime action axis from its serializable definition.
local function create_axis(definition)
  return ActionAxis.new({
    negative_action = definition.negative_action,
    positive_action = definition.positive_action,
    activation = ActionActivation.new(definition.activation or "down")
  })
end

-- Creates one runtime action vector from its serializable definition.
local function create_vector(definition)
  return ActionVector.new({
    x_axis = create_axis(definition.x_axis),
    y_axis = create_axis(definition.y_axis)
  })
end

-- Creates a runtime control profile from a serializable definition.
function ControlProfileFactory.create(definition)
  assert(type(definition) == "table", "control profile definition must be a table")

  local axes = {}
  local vectors = {}
  local actions = {}

  for name, axis_definition in pairs(definition.axes or {}) do
    axes[name] = create_axis(axis_definition)
  end
  for name, vector_definition in pairs(definition.vectors or {}) do
    vectors[name] = create_vector(vector_definition)
  end
  for name, action in pairs(definition.actions or {}) do
    actions[name] = action
  end

  return ControlProfile.new({
    axes = axes,
    vectors = vectors,
    actions = actions
  })
end

return ControlProfileFactory
