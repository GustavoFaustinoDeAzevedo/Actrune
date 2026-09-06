local ImageBillboardVisual = require("engine.render.image_billboard_visual")

local ImageBillboardVisualFactory = {}

-- Creates a resource factory backed by one fixed drawable image source type.
function ImageBillboardVisualFactory.for_source_type(source_resource_type)
  assert(type(source_resource_type) == "string" and source_resource_type ~= "",
    "image billboard visual factory requires a non-empty source resource type")

  return function(definition, context)
    assert(type(definition) == "table",
      "image billboard visual definition must be a table")
    assert(context ~= nil and type(context.resolve_resource) == "function",
      "image billboard visual factory requires resource resolution")

    -- The source remains an independent resource such as an image region.
    local source = context.resolve_resource(
      source_resource_type,
      definition.source
    )

    assert(source ~= nil and type(source.get_dimensions) == "function"
      and type(source.draw) == "function",
      "image billboard visual source must be drawable")

    -- ImageBillboardVisual is stateless and can therefore be shared by many entities.
    return ImageBillboardVisual.new({
      source = source
    })
  end
end

return ImageBillboardVisualFactory
