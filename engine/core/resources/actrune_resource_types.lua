local InputMapFactory = require("engine.core.input.input_map_factory")
local GridMetricsFactory = require("engine.world.grid.grid_metrics_factory")
local ControlProfileFactory = require("engine.world.control.control_profile_factory")
local PhysicalMaterialFactory = require("engine.world.physics.physical_material_factory")
local ImageResourceFactory = require("engine.render.image_resource_factory")
local ImageRegionFactory = require("engine.render.image_region_factory")
local ResourceSequenceFactory = require("engine.core.resources.resource_sequence_factory")
local AnimationClipFactory = require("engine.core.animation.animation_clip_factory")
local AnimationFrameTrackFactory = require("engine.core.animation.animation_frame_track_factory")
local AnimationFrameTrackSetFactory = require("engine.core.animation.animation_frame_track_set_factory")
local DirectionalImageAnimationVisualFactory = require("engine.render.directional_image_animation_visual_factory")
local EntityVisualBindingFactory = require("engine.render.entity_visual_binding_factory")
local AnimatedEntityVisualConfigurationFactory = require("engine.render.animated_entity_visual_configuration_factory")
local ImageBillboardVisualFactory = require("engine.render.image_billboard_visual_factory")

local ActruneResourceTypes = {}

-- Registers the built-in Actrune resource types in a project configuration register.
function ActruneResourceTypes.register(register)
  assert(register ~= nil, "Actrune resource types require a project configuration register")

  register:register_resource_type("image", ImageResourceFactory.create, {
    fields = {
      { name = "path", type = "string", required = true }
    }
  })

  register:register_resource_type("image_region", ImageRegionFactory.create, {
    fields = {
      {
        name = "image",
        type = "resource_reference",
        resource_type = "image",
        required = true
      },
      {
        name = "x",
        type = "number",
        min = 0,
        default = 0
      },
      {
        name = "y",
        type = "number",
        min = 0,
        default = 0
      },
      {
        name = "width",
        type = "number",
        required = true,
        min_exclusive = 0
      },
      {
        name = "height",
        type = "number",
        required = true,
        min_exclusive = 0
      }
    }
  })

  register:register_resource_type("image_billboard_visual", ImageBillboardVisualFactory.for_source_type("image_region"),
    {
      fields = {
        {
          name = "source",
          type = "resource_reference",
          resource_type = "image_region",
          required = true
        }
      }
    })

  register:register_resource_type("image_region_sequence", ResourceSequenceFactory.for_type("image_region"), {
    fields = {
      {
        name = "items",
        type = "resource_reference_list",
        resource_type = "image_region",
        required = true,
        min_items = 1
      }
    }
  })

  register:register_resource_type("physical_material", PhysicalMaterialFactory.create, {
    fields = {
      {
        name = "properties",
        type = "property_map",
        allow_custom = true,
        suggestions = {
          { name = "density",     type = "number", min = 0 },
          { name = "restitution", type = "number", min = 0 },
          { name = "friction",    type = "number", min = 0 }
        }
      }
    }
  })

  register:register_resource_type("grid_metrics", GridMetricsFactory.create, {
    fields = {
      { name = "cell_width",  type = "number", required = true, min_exclusive = 0 },
      { name = "cell_height", type = "number", required = true, min_exclusive = 0 }
    }
  })

  register:register_resource_type("animation_clip", AnimationClipFactory.create, {
    fields = {
      {
        name = "frame_durations",
        type = "number_list",
        required = true,
        min_items = 1,
        min_exclusive = 0
      },
      {
        name = "loop",
        type = "boolean",
        default = true
      }
    }
  })

  register:register_resource_type("image_animation_track",
    AnimationFrameTrackFactory.for_sequence_type("image_region_sequence"), {
      fields = {
        {
          name = "clip",
          type = "resource_reference",
          resource_type = "animation_clip",
          required = true
        },
        {
          name = "sequence",
          type = "resource_reference",
          resource_type = "image_region_sequence",
          required = true
        }
      }
    })

  register:register_resource_type("image_animation_track_set",
    AnimationFrameTrackSetFactory.for_track_type("image_animation_track"), {
      fields = {
        {
          name = "tracks",
          type = "resource_reference_list",
          resource_type = "image_animation_track",
          required = true,
          min_items = 1
        }
      }
    })

  register:register_resource_type("directional_image_animation_visual",
    DirectionalImageAnimationVisualFactory.create, {
      fields = {
        {
          name = "track_set",
          type = "resource_reference",
          resource_type = "image_animation_track_set",
          required = true
        },
        {
          name = "angle_offset",
          type = "number",
          default = 0
        }
      }
    })

  register:register_resource_type("directional_image_animation_binding",
    EntityVisualBindingFactory.for_visual_type("directional_image_animation_visual"), {
      fields = {
        {
          name = "entity",
          type = "entity_reference",
          required = true
        },
        {
          name = "visual",
          type = "resource_reference",
          resource_type = "directional_image_animation_visual",
          required = true
        }
      }
    })

  register:register_resource_type("image_billboard_binding",
    EntityVisualBindingFactory.for_visual_type("image_billboard_visual"), {
      fields = {
        {
          name = "entity",
          type = "entity_reference",
          required = true
        },
        {
          name = "visual",
          type = "resource_reference",
          resource_type = "image_billboard_visual",
          required = true
        }
      }
    })

  register:register_resource_type("image_billboard_binding_sequence",
    ResourceSequenceFactory.for_type("image_billboard_binding"), {
    fields = {
      {
        name = "items",
        type = "resource_reference_list",
        resource_type = "image_billboard_binding",
        required = true,
        min_items = 1
      }
    }
  }
  )

  register:register_resource_type("directional_image_animation_binding_sequence",
    ResourceSequenceFactory.for_type("directional_image_animation_binding"), {
      fields = {
        {
          name = "items",
          type = "resource_reference_list",
          resource_type = "directional_image_animation_binding",
          required = true,
          min_items = 1
        }
      }
    })

  register:register_resource_type("animated_entity_visual_configuration",
    AnimatedEntityVisualConfigurationFactory.for_binding_sequence_type("directional_image_animation_binding_sequence"), {
      fields = {
        {
          name = "bindings",
          type = "resource_reference",
          resource_type = "directional_image_animation_binding_sequence",
          required = true
        }
      }
    })

  register:register_resource_type("input_map", InputMapFactory.create)
  register:register_resource_type("control_profile", ControlProfileFactory.create)
end

return ActruneResourceTypes
