local ValueExpressionFactory = require("engine.core.values.value_expression_factory")

local DisplacementExpressionFactory = {}

local builders = {}

-- Creates a displacement that scales both direction components by one value.
local function create_uniform(definition, context)
  local amount = ValueExpressionFactory.create(definition.amount, context)

  return {
    -- Resolves a displacement by uniformly scaling the supplied direction.
    resolve = function(self, direction_x, direction_y, resolve_context)
      local value = amount:resolve(resolve_context)
      return direction_x * value, direction_y * value
    end
  }
end

-- Creates a displacement that independently scales the horizontal and vertical direction components.
local function create_axes(definition, context)
  local x_amount = ValueExpressionFactory.create(definition.x, context)
  local y_amount = ValueExpressionFactory.create(definition.y, context)

  return {
    -- Resolves a displacement using independent values for each direction axis.
    resolve = function(self, direction_x, direction_y, resolve_context)
      local x = x_amount:resolve(resolve_context)
      local y = y_amount:resolve(resolve_context)
      return direction_x * x, direction_y * y
    end
  }
end

-- Registers a constructor for a named displacement expression type.
function DisplacementExpressionFactory.register_type(type_name, builder)
  assert(type(type_name) == "string", "displacement expression type name must be a string")
  assert(type(builder) == "function", "displacement expression builder must be a function")

  builders[type_name] = builder
end

-- Creates a displacement expression from a serializable definition.
function DisplacementExpressionFactory.create(definition, context)
  assert(type(definition) == "table", "displacement expression definition must be a table")
  assert(type(definition.type) == "string", "displacement expression requires a type")

  local builder = builders[definition.type]
  assert(builder ~= nil, "unknown displacement expression type: " .. tostring(definition.type))

  return builder(definition, context or {})
end

DisplacementExpressionFactory.register_type("uniform", create_uniform)
DisplacementExpressionFactory.register_type("axes", create_axes)

return DisplacementExpressionFactory
