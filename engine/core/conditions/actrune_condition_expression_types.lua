local FactoryRegistry = require("engine.core.definitions.factory_registry")

local ActruneConditionExpressionTypes = {}

-- Registers the built-in Actrune condition expression family in a type catalog.
function ActruneConditionExpressionTypes.register(catalog)
  assert(catalog ~= nil, "Actrune condition expression types require a type catalog")

  if not catalog:has_registry("condition_expression") then
    catalog:register_registry("condition_expression", FactoryRegistry.new({ kind = "condition expression" }))
  end

  catalog:register("condition_expression", "component_property_exists", function(definition)
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
  end, {
    fields = {
      { name = "component", type = "string", required = true },
      { name = "property",  type = "string", required = true }
    }
  })

  catalog:register("condition_expression", "not", function(definition, context)
    local condition = context.catalog:create("condition_expression", definition.condition, context)

    return {
      -- Returns the inverse result of the wrapped condition.
      resolve = function(self, resolve_context)
        return not condition:resolve(resolve_context)
      end
    }
  end, {
    fields = {
      { name = "condition", type = "condition_expression", required = true }
    }
  })
end

return ActruneConditionExpressionTypes
