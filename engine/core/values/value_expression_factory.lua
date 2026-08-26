local Value = require("engine.core.values.value")

local ValueExpressionFactory = {}

local builders = {}

-- Creates a constant runtime value expression.
local function create_value(definition)
  assert(type(definition.value) == "number", "value expression requires a numeric value")
  return Value.new(definition.value)
end

-- Creates a runtime value expression scaled by delta time.
local function create_delta_time(definition, context)
  local source = ValueExpressionFactory.create(definition.value, context)

  return {
    -- Resolves the source value and scales it by the current delta time.
    resolve = function(self, resolve_context)
      resolve_context = resolve_context or {}

      assert(type(resolve_context.dt) == "number", "delta_time value requires context.dt")

      return source:resolve(resolve_context) * resolve_context.dt
    end
  }
end

-- Creates an expression that reads one numeric property from a project resource.
local function create_resource_property(definition, context)
  assert(context ~= nil and context.factory ~= nil, "resource_property value requires an entity factory")
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

      assert(
        type(value) == "number",
        "resource property must resolve to a number: "
        .. definition.resource_type
        .. "."
        .. definition.resource
        .. "."
        .. definition.property
      )

      return value
    end
  }
end

-- Creates an expression that reads one numeric property from an entity component.
local function create_component_property(definition)
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
      assert(type(component.get) == "function", "component does not expose readable properties: " .. definition
      .component)

      local value = component:get(definition.property)

      assert(
        type(value) == "number",
        "component property must resolve to a number: "
        .. definition.component
        .. "."
        .. definition.property
      )

      return value
    end
  }
end

-- Registers a constructor for a named value expression type.
function ValueExpressionFactory.register_type(type_name, builder)
  assert(type(type_name) == "string", "value expression type name must be a string")
  assert(type(builder) == "function", "value expression builder must be a function")

  builders[type_name] = builder
end

-- Creates a runtime value expression from a serializable definition.
function ValueExpressionFactory.create(definition, context)
  assert(type(definition) == "table", "value expression definition must be a table")
  assert(type(definition.type) == "string", "value expression requires a type")

  local builder = builders[definition.type]
  assert(builder ~= nil, "unknown value expression type: " .. tostring(definition.type))

  return builder(definition, context or {})
end

ValueExpressionFactory.register_type("value", create_value)
ValueExpressionFactory.register_type("delta_time", create_delta_time)
ValueExpressionFactory.register_type("resource_property", create_resource_property)
ValueExpressionFactory.register_type("component_property", create_component_property)

return ValueExpressionFactory
