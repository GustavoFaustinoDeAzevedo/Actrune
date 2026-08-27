local FactoryRegistry = require("engine.core.definitions.factory_registry")
local ValueExpressionFactory = require("engine.core.values.value_expression_factory")

local DisplacementExpressionFactory = {}

local registry = FactoryRegistry.new({
  kind = "displacement expression"
})

-- Creates a displacement that scales both direction components by one value.
local function create_uniform(definition, context)
  assert(context.catalog ~= nil, "uniform displacement requires a type catalog")

  local amount = context.catalog:create("value_expression", definition.amount, context)

  return {
    -- Resolves a displacement by uniformly scaling the supplied direction.
    resolve = function(self, direction_x, direction_y, resolve_context)
      local value = amount:resolve(resolve_context)
      return direction_x * value, direction_y * value
    end
  }
end

-- Creates a displacement that independently scales horizontal and vertical direction components.
local function create_axes(definition, context)
  assert(context.catalog ~= nil, "axes displacement requires a type catalog")

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
end

-- Registers a named displacement expression factory and optional metadata.
function DisplacementExpressionFactory.register_type(type_name, factory, definition)
  registry:register(type_name, factory, definition)
end

-- Creates a displacement expression from a serializable definition.
function DisplacementExpressionFactory.create(definition, context)
  assert(type(definition) == "table", "displacement expression definition must be a table")
  assert(type(definition.type) == "string", "displacement expression requires a type")

  return registry:create(definition.type, definition, context)
end

-- Returns the registry containing all available displacement expression types.
function DisplacementExpressionFactory.get_registry()
  return registry
end

DisplacementExpressionFactory.register_type("uniform", create_uniform, {
  fields = {
    { name = "amount", type = "value_expression", required = true }
  }
})

DisplacementExpressionFactory.register_type("axes", create_axes, {
  fields = {
    { name = "x", type = "value_expression", required = true },
    { name = "y", type = "value_expression", required = true }
  }
})

return DisplacementExpressionFactory
