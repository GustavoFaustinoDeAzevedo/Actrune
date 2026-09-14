-- Declares travelling and global actors shared by the resident maps.
local definitions = {
  -- Defines the dynamic physics test actor.
  bounce_ball = {
    id = "bounce_ball",
    transform = { x = 280, y = 200 },

    shapes = {
      physics = { type = "circle", radius = 10, material = "ball" }
    },

    components = {
      rigid_body = {
        type = "rigid_body",
        body_type = "dynamic",
        shapes = { "physics" }
      }
    }
  },

  -- Defines the continuously controlled actor and its spatial capabilities.
  player = {
    id = "player",
    transform = { x = 260, y = 150, rotation = math.rad(270) },

    shapes = {
      collision = {
        type = "polygon",
        points = {
          { x = -15, y = -15 },
          { x = 15,  y = -15 },
          { x = 15,  y = 15 },
          { x = -15, y = 15 }
        }
      }
    },

    components = {
      collision_height = {
        type = "vertical_range",
        elevation_component = "elevation",
        lower = 0,
        upper = 12
      },
      interaction_height = {
        type = "vertical_range",
        elevation_component = "elevation",
        lower = 0,
        upper = 12
      },
      elevation = {
        type = "spatial_elevation",
        levels = "main",
        level = 0,
        offset = 0
      },
      controls = { type = "controls", profile = "player" },
      movement_direction = { type = "facing_direction" },

      elevation_control = {
        type = "elevation_control",
        controls = "controls",
        input = "elevate",
        elevation_component = "elevation",
        source_shape = "collision",
        target_shape = "collision",
        source_vertical_range = "collision_height",
        target_vertical_range = "collision_height",
        amount = { type = "value", value = 16 },
        application = { type = "on_activation" },
        control_order = 15
      },

      rotation_control = {
        type = "rotation_control",
        controls = "controls",
        input = "turn",
        amount = { type = "value", value = math.rad(90) },
        application = { type = "on_activation" },
        control_order = 15
      },

      translation_control = {
        type = "translation_control",
        controls = "controls",
        input = "move",
        direction = "movement_direction",
        source_vertical_range = "collision_height",
        target_vertical_range = "collision_height",

        displacement = {
          type = "uniform",
          amount = {
            type = "delta_time",
            value = { type = "value", value = 250 }
          }
        },

        application = { type = "while_active" },
        source_shape = "collision",
        target_shape = "collision",
        control_order = 20
      },

      spatial_action_control = {
        type = "spatial_action_control",
        controls = "controls",
        input = "interact",
        control_order = 30
      }
    }
  },

  -- Defines the actor that switches between grid and free movement contexts.
  step_player = {
    id = "step_player",
    transform = { x = 450, y = 150 },

    shapes = {
      collision = {
        type = "polygon",
        points = {
          { x = -5, y = -5 },
          { x = 5,  y = -5 },
          { x = 5,  y = 5 },
          { x = -5, y = 5 }
        }
      }
    },

    components = {
      collision_height = {
        type = "vertical_range",
        elevation_component = "elevation",
        lower = 0,
        upper = 12
      },
      interaction_height = {
        type = "vertical_range",
        elevation_component = "elevation",
        lower = 0,
        upper = 12
      },
      elevation = {
        type = "spatial_elevation",
        levels = "main",
        level = 0,
        offset = 0
      },
      controls = { type = "controls", profile = "step_player" },
      grid_context = { type = "grid_context", metrics = "small_grid" },
      movement_direction = { type = "facing_direction" },

      grid_translation = {
        type = "translation_control",
        controls = "controls",
        input = "move",
        direction = "movement_direction",
        source_vertical_range = "collision_height",
        target_vertical_range = "collision_height",
        direction_policy = { type = "last_changed_axis", initial_axis = "x" },

        displacement = {
          type = "axes",
          x = {
            type = "component_property",
            component = "grid_context",
            property = "cell_width"
          },
          y = {
            type = "component_property",
            component = "grid_context",
            property = "cell_height"
          }
        },

        application = {
          type = "when",
          condition = {
            type = "component_property_exists",
            component = "grid_context",
            property = "cell_width"
          },
          application = { type = "on_change", fields = { "input_x", "input_y" } }
        },

        source_shape = "collision",
        target_shape = "collision",
        control_order = 10
      },

      free_translation = {
        type = "translation_control",
        controls = "controls",
        input = "move",
        direction = "movement_direction",
        source_vertical_range = "collision_height",
        target_vertical_range = "collision_height",
        direction_policy = { type = "last_changed_axis", initial_axis = "x" },

        displacement = {
          type = "uniform",
          amount = {
            type = "delta_time",
            value = { type = "value", value = 120 }
          }
        },

        application = {
          type = "when",
          condition = {
            type = "not",
            condition = {
              type = "component_property_exists",
              component = "grid_context",
              property = "cell_width"
            }
          },
          application = { type = "while_active" }
        },

        source_shape = "collision",
        target_shape = "collision",
        control_order = 20
      }
    }
  }
}

return definitions
