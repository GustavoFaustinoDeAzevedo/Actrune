local ConditionExpressionFactory = {}

local builders = {}

-- Creates a condition that checks whether an entity component exposes a property.
local function create_component_property_exists(definition)
  assert(type(definition.component) == "string", "component_property_exists requires a component")
  assert(type(definition.property) == "string", "component_property_exists requires a property")

  return {
    -- Returns whether the requested component property currently exists.
    resolve = function(self, context)
      context = context or {}

      local entity = context.entity
      assert(entity ~= nil, "component_property_exists requires context.entity")

      local component = entity:get_component(definition.component)
      if component == nil or type(component.get) ~= "function" then return false end

      return component:get(definition.property) ~= nil
    end
  }
end

-- Creates a condition that negates another condition.
local function create_not(definition, context)
  local condition = ConditionExpressionFactory.create(definition.condition, context)

  return {
    -- Returns the inverse result of the wrapped condition.
    resolve = function(self, resolve_context)
      return not condition:resolve(resolve_context)
    end
  }
end

-- Registers a constructor for a named condition expression type.
function ConditionExpressionFactory.register_type(type_name, builder)
  assert(type(type_name) == "string", "condition expression type name must be a string")
  assert(type(builder) == "function", "condition expression builder must be a function")

  builders[type_name] = builder
end

-- Creates a runtime condition expression from a serializable definition.
function ConditionExpressionFactory.create(definition, context)
  assert(type(definition) == "table", "condition expression definition must be a table")
  assert(type(definition.type) == "string", "condition expression requires a type")

  local builder = builders[definition.type]
  assert(builder ~= nil, "unknown condition expression type: " .. tostring(definition.type))

  return builder(definition, context or {})
end

ConditionExpressionFactory.register_type("component_property_exists", create_component_property_exists)
ConditionExpressionFactory.register_type("not", create_not)

return ConditionExpressionFactory
