local DirectionalAnimationVisualTemplate = require("engine.render.directional_animation_visual_template")
local ImageAnimationVisualFactory = require("engine.render.image_animation_visual_factory")

local DirectionalImageAnimationVisualFactory = {}

-- Creates a directional animation visual template from one image animation track set resource.
function DirectionalImageAnimationVisualFactory.create(definition, context)
  assert(type(definition) == "table",
    "directional image animation visual definition must be a table")
  assert(context ~= nil and type(context.resolve_resource) == "function",
    "directional image animation visual factory requires resource resolution")

  local track_set = context.resolve_resource(
    "image_animation_track_set",
    definition.track_set
  )

  return DirectionalAnimationVisualTemplate.new(
    track_set,
    ImageAnimationVisualFactory.create,
    {
      angle_offset = definition.angle_offset or 0
    }
  )
end

return DirectionalImageAnimationVisualFactory
