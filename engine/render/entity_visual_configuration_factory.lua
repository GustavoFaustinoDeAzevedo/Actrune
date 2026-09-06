local EntityVisualConfiguration =
    require("engine.render.entity_visual_configuration")

local EntityVisualConfigurationFactory = {}

-- Creates a visual configuration factory specialized for one binding sequence resource type.
function EntityVisualConfigurationFactory.for_binding_sequence_type(binding_sequence_type)
  assert(type(binding_sequence_type) == "string" and binding_sequence_type ~= "",
    "entity visual configuration factory requires a non-empty binding sequence type")

  return function(definition, context)
    assert(type(definition) == "table",
      "entity visual configuration definition must be a table")
    assert(context ~= nil and type(context.resolve_resource) == "function",
      "entity visual configuration factory requires resource resolution")

    -- The specialized resource type determines which binding sequence this configuration may reference.
    local bindings = context.resolve_resource(
      binding_sequence_type,
      definition.bindings
    )

    return EntityVisualConfiguration.new(bindings)
  end
end

return EntityVisualConfigurationFactory
