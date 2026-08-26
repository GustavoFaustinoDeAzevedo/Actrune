local ConditionExpressionFactory = require("engine.core.conditions.condition_expression_factory")

local ControlApplicationFactory = {}

local builders = {}

-- Copies an application context while replacing its active state.
local function with_active(context, active)
  local result = {}

  for name, value in pairs(context or {}) do result[name] = value end

  result.active = active
  return result
end

-- Creates an application policy that executes every update while the control intent is active.
local function create_while_active()
  local policy = {}

  -- Returns whether the controlled operation should be applied during this update.
  function policy:should_apply(context)
    return context.active == true
  end

  return policy
end

-- Creates an application policy that executes once when the control intent becomes active.
local function create_on_activation()
  local policy = {
    was_active = false
  }

  -- Returns whether this update represents a new control activation.
  function policy:should_apply(context)
    local active = context.active == true

    if not active then
      self.was_active = false
      return false
    end

    if self.was_active then return false end

    self.was_active = true
    return true
  end

  return policy
end

-- Creates an application policy enabled only while a condition is satisfied.
local function create_when(definition, context)
  local condition = ConditionExpressionFactory.create(definition.condition, context)
  local application = ControlApplicationFactory.create(definition.application, context)

  local policy = {}

  -- Applies the wrapped policy only while its condition is satisfied.
  function policy:should_apply(resolve_context)
    local enabled = condition:resolve(resolve_context)
    return application:should_apply(with_active(resolve_context, enabled and resolve_context.active == true))
  end

  return policy
end

-- Registers a constructor for a named control application policy type.
function ControlApplicationFactory.register_type(type_name, builder)
  assert(type(type_name) == "string", "control application type name must be a string")
  assert(type(builder) == "function", "control application builder must be a function")

  builders[type_name] = builder
end

-- Creates a control application policy from a serializable definition.
function ControlApplicationFactory.create(definition, context)
  assert(type(definition) == "table", "control application definition must be a table")
  assert(type(definition.type) == "string", "control application definition requires a type")

  local builder = builders[definition.type]
  assert(builder ~= nil, "unknown control application type: " .. tostring(definition.type))

  return builder(definition, context or {})
end

ControlApplicationFactory.register_type("while_active", create_while_active)
ControlApplicationFactory.register_type("on_activation", create_on_activation)
ControlApplicationFactory.register_type("when", create_when)

return ControlApplicationFactory
