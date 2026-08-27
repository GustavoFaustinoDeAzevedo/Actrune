local FactoryRegistry = require("engine.core.definitions.factory_registry")
local Value = require("engine.core.values.value")

local ActruneValueExpressionTypes = {}

-- Registers the built-in Actrune value expression family in a type catalog.
function ActruneValueExpressionTypes.register(catalog)
  assert(catalog ~= nil, "Actrune value expression types require a type catalog")

  if not catalog:has_registry("value_expression") then
    catalog:register_registry("value_expression", FactoryRegistry.new({ kind = "value expression" }))
  end

  catalog:register("value_expression", "value", function(definition)
    assert(type(definition.value) == "number", "value expression requires a numeric value")
    return Value.new(definition.value)
  end, {
    fields = {
      { name = "value", type = "number", required = true }
    }
  })

  catalog:register("value_expression", "delta_time", function(definition, context)
    local source = context.catalog:create("value_expression", definition.value, context)

    return {
      -- Resolves the wrapped value and scales it by the current delta time.
      resolve = function(self, resolve_context)
        resolve_context = resolve_context or {}
        assert(type(resolve_context.dt) == "number", "delta_time value requires context.dt")
        return source:resolve(resolve_context) * resolve_context.dt
      end
    }
  end, {
    fields = {
      { name = "value", type = "value_expression", required = true }
    }
  })

  catalog:register("value_expression", "resource_property", function(definition, context)
    assert(context.factory ~= nil, "resource_property value requires an entity factory")
    assert(type(definition.resource_type) == "string", "resource_property requires a resource_type")
    assert(type(definition.resource) == "string", "resource_property requires a resource")
    assert(type(definition.property) == "string", "resource_property requires a property")

    local resource = context.factory:get_resource(definition.resource_type, definition.resource)
    assert(resource ~= nil, "unknown " .. definition.resource_type .. " resource: " .. definition.resource)
    assert(type(resource.get) == "function",
      "resource does not expose readable properties: " .. definition.resource_type .. "." .. definition.resource)

    return {
      -- Returns the configured numeric property from the referenced resource.
      resolve = function()
        local value = resource:get(definition.property)
        assert(type(value) == "number",
          "resource property must resolve to a number: " ..
          definition.resource_type .. "." .. definition.resource .. "." .. definition.property)
        return value
      end
    }
  end, {
    fields = {
      { name = "resource_type", type = "string", required = true },
      { name = "resource",      type = "string", required = true },
      { name = "property",      type = "string", required = true }
    }
  })

  catalog:register("value_expression", "component_property", function(definition)
    assert(type(definition.component) == "string", "component_property requires a component")
    assert(type(definition.property) == "string", "component_property requires a property")

    return {
      -- Returns the configured numeric property from a component on the resolving entity.
      resolve = function(self, resolve_context)
        resolve_context = resolve_context or {}

        local entity = resolve_context.entity
        assert(entity ~= nil, "component_property value requires context.entity")

        local component = entity:get_component(definition.component)
        assert(component ~= nil, "component_property references missing component: " .. definition.component)
        assert(type(component.get) == "function",
          "component does not expose readable properties: " .. definition.component)

        local value = component:get(definition.property)
        assert(type(value) == "number",
          "component property must resolve to a number: " .. definition.component .. "." .. definition.property)

        return value
      end
    }
  end, {
    fields = {
      { name = "component", type = "string", required = true },
      { name = "property",  type = "string", required = true }
    }
  })
end

return ActruneValueExpressionTypes
