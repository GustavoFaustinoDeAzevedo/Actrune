local AnimatedEntityVisualConfiguration = require("engine.render.animated_entity_visual_configuration")

local AnimatedEntityVisualConfigurationFactory = {}

-- Creates a configuration factory backed by one fixed visual binding sequence type.
function AnimatedEntityVisualConfigurationFactory.for_binding_sequence_type(binding_sequence_type)
  assert(type(binding_sequence_type) == "string" and binding_sequence_type ~= "",
    "animated entity visual configuration factory requires a non-empty binding sequence type")

  return function(definition, context)
    assert(type(definition) == "table",
      "animated entity visual configuration definition must be a table")
    assert(context ~= nil and type(context.resolve_resource) == "function",
      "animated entity visual configuration factory requires resource resolution")

    local bindings = context.resolve_resource(
      binding_sequence_type,
      definition.bindings
    )

    return AnimatedEntityVisualConfiguration.new(bindings)
  end
end

return AnimatedEntityVisualConfigurationFactory
