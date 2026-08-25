local Value = require("engine.core.values.value")

local ValueExpressionFactory = {}

-- Creates a constant runtime value expression.
local function create_value(definition)
  assert(type(definition.value) == "number", "value expression requires a numeric value")
  return Value.new(definition.value)
end

-- Creates a runtime value expression scaled by delta time.
local function create_delta_time(definition)
  local source = ValueExpressionFactory.create(definition.value)

  return {
    -- Resolves the source value and scales it by the current delta time.
    resolve = function(self, context)
      context = context or {}
      assert(type(context.dt) == "number", "delta_time value requires context.dt")
      return source:resolve(context) * context.dt
    end
  }
end

-- Creates a runtime value expression from a serializable definition.
function ValueExpressionFactory.create(definition)
  assert(type(definition) == "table", "value expression definition must be a table")
  assert(type(definition.type) == "string", "value expression requires a type")

  if definition.type == "value" then return create_value(definition) end
  if definition.type == "delta_time" then return create_delta_time(definition) end

  error("unknown value expression type: " .. tostring(definition.type))
end

return ValueExpressionFactory
