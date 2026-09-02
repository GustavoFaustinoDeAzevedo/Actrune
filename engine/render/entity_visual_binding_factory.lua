local EntityVisualBinding = require("engine.render.entity_visual_binding")

local EntityVisualBindingFactory = {}

-- Creates a resource factory that binds entities to one fixed visual resource type.
function EntityVisualBindingFactory.for_visual_type(visual_resource_type)
  assert(type(visual_resource_type) == "string" and visual_resource_type ~= "",
    "entity visual binding factory requires a non-empty visual resource type")

  return function(definition, context)
    assert(type(definition) == "table",
      "entity visual binding definition must be a table")
    assert(context ~= nil and type(context.resolve_resource) == "function",
      "entity visual binding factory requires resource resolution")

    local visual_template = context.resolve_resource(
      visual_resource_type,
      definition.visual
    )

    return EntityVisualBinding.new(
      definition.entity,
      visual_template
    )
  end
end

return EntityVisualBindingFactory
