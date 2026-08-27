local FactoryRegistry = require("engine.core.definitions.factory_registry")

local ConditionExpressionFactory = {}

local registry = FactoryRegistry.new({
  kind = "condition expression"
})

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
  assert(context.catalog ~= nil, "not condition requires a type catalog")

  local condition = context.catalog:create("condition_expression", definition.condition, context)

  return {
    -- Returns the inverse result of the wrapped condition.
    resolve = function(self, resolve_context)
      return not condition:resolve(resolve_context)
    end
  }
end

-- Registers a named condition expression factory and optional metadata.
function ConditionExpressionFactory.register_type(type_name, factory, definition)
  registry:register(type_name, factory, definition)
end

-- Creates a runtime condition expression from a serializable definition.
function ConditionExpressionFactory.create(definition, context)
  assert(type(definition) == "table", "condition expression definition must be a table")
  assert(type(definition.type) == "string", "condition expression requires a type")

  return registry:create(definition.type, definition, context)
end

-- Returns the registry containing all available condition expression types.
function ConditionExpressionFactory.get_registry()
  return registry
end

ConditionExpressionFactory.register_type("component_property_exists", create_component_property_exists, {
  fields = {
    { name = "component", type = "string", required = true },
    { name = "property",  type = "string", required = true }
  }
})

ConditionExpressionFactory.register_type("not", create_not, {
  fields = {
    { name = "condition", type = "condition_expression", required = true }
  }
})

return ConditionExpressionFactory
