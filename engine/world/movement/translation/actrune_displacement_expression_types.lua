local FactoryRegistry = require("engine.core.definitions.factory_registry")

local ActruneDisplacementExpressionTypes = {}

-- Registers the built-in Actrune displacement expression family in a type catalog.
function ActruneDisplacementExpressionTypes.register(catalog)
  assert(catalog ~= nil, "Actrune displacement expression types require a type catalog")

  if not catalog:has_registry("displacement_expression") then
    catalog:register_registry("displacement_expression", FactoryRegistry.new({ kind = "displacement expression" }))
  end

  catalog:register("displacement_expression", "uniform", function(definition, context)
    local amount = context.catalog:create("value_expression", definition.amount, context)

    return {
      -- Resolves a displacement by uniformly scaling the supplied direction.
      resolve = function(self, direction_x, direction_y, resolve_context)
        local value = amount:resolve(resolve_context)
        return direction_x * value, direction_y * value
      end
    }
  end, {
    fields = {
      { name = "amount", type = "value_expression", required = true }
    }
  })

  catalog:register("displacement_expression", "axes", function(definition, context)
    local x_amount = context.catalog:create("value_expression", definition.x, context)
    local y_amount = context.catalog:create("value_expression", definition.y, context)

    return {
      -- Resolves a displacement using independent values for each direction axis.
      resolve = function(self, direction_x, direction_y, resolve_context)
        local x = x_amount:resolve(resolve_context)
        local y = y_amount:resolve(resolve_context)
        return direction_x * x, direction_y * y
      end
    }
  end, {
    fields = {
      { name = "x", type = "value_expression", required = true },
      { name = "y", type = "value_expression", required = true }
    }
  })
end

return ActruneDisplacementExpressionTypes