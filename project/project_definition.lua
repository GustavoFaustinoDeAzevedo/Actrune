local project_definition = {
  resources = {

    map_location_binding = {
      main = {
        entity = "player",
        layout = "main"
      }
    },

    map_layout = {
      main = {
        maps = {
          west_hall = require("project.maps.west_hall"),
          east_hall = require("project.maps.east_hall")
        }
      }
    },

    world_topology = {
      main = {
        min_x = 0,
        min_y = 0,
        width = 1024,
        height = 768,
        loop_x = true,
        loop_y = false
      }
    },

    test_scene_render_configuration = {
      main = {
        render_mode = "orthographic", -- "orthographic" or "perspective"
        orthographic_elevation_scale = 1,

        world_camera_target_entity = "player",
        world_camera_elevation_component = "elevation",

        -- Fixed view bounds for the orthographic scene.
        world_camera_min_x = -1024,
        world_camera_min_y = -256,
        world_camera_max_x = 1024,
        world_camera_max_y = 1536,

        projected_camera_target_entity = "player",

        world_camera_position_half_life = 0.08,
        projected_camera_position_half_life = 0.08,
        projected_camera_rotation_half_life = 0.1,
        projected_camera_forward_offset = -96,
        camera_elevation = 32,
        camera_elevation_component = "elevation",
        camera_elevation_half_life = 0.08,
        reference_distance = 32,

        ground_levels = "main",
        ground_level = 0,
        ground_region_width = 2048,
        ground_region_height = 2048,

        horizon = 0.3,
        near_distance = 32,
        far_distance = 800,
        horizontal_fov = math.rad(75)
      }
    },

    static_entity_visual_configuration = {
      projected_static_visuals = {
        bindings = "projected_static_entities"
      }
    },

    image = {
      characters_1 = {
        path = "project/assets/default_img_1.png"
      },
      characters_2 = {
        path = "project/assets/default_img_2.png"
      },
      characters_3 = {
        path = "project/assets/default_img_3.png"
      },
      characters_4 = {
        path = "project/assets/default_img_4.png"
      },
      characters_5 = {
        path = "project/assets/default_img_5.png"
      },
      characters_6 = {
        path = "project/assets/default_img_6.png"
      },
      characters_7 = {
        path = "project/assets/default_img_7.png"
      },
      characters_8 = {
        path = "project/assets/default_img_8.png"
      },

    },
    image_region = {
      player_front_1 = {
        image = "characters_1",
        x = 0,
        y = 0,
        width = 64,
        height = 64
      },

      player_front_2 = {
        image = "characters_2",
        x = 0,
        y = 0,
        width = 64,
        height = 64
      },

      player_right_1 = {
        image = "characters_3",
        x = 0,
        y = 0,
        width = 64,
        height = 64
      },

      player_right_2 = {
        image = "characters_4",
        x = 0,
        y = 0,
        width = 64,
        height = 64
      },

      player_back_1 = {
        image = "characters_5",
        x = 0,
        y = 0,
        width = 64,
        height = 64
      },

      player_back_2 = {
        image = "characters_6",
        x = 0,
        y = 0,
        width = 64,
        height = 64
      },

      player_left_1 = {
        image = "characters_7",
        x = 0,
        y = 0,
        width = 64,
        height = 64
      },

      player_left_2 = {
        image = "characters_8",
        x = 0,
        y = 0,
        width = 64,
        height = 64
      }
    },
    animation_clip = {
      player_walk = {
        frame_durations = {
          0.18,
          0.18,
        },
        loop = true
      },

      ball_pulse = {
        frame_durations = {
          0.3,
          0.05,
          0.05,
          0.2
        },
        loop = true
      }
    },

    image_billboard_visual = {
      static_test_character = {
        source = "player_front_1"
      }
    },

    image_billboard_binding = {
      static_test_character = {
        entity = "step_player",
        visual = "static_test_character",
        elevation_component = "elevation"
      },
    },

    image_billboard_binding_sequence = {
      projected_static_entities = {
        items = {
          "static_test_character",
        }
      }
    },

    image_region_sequence = {
      player_front_walk = {
        items = {
          "player_front_1",
          "player_front_2"
        }
      },

      player_right_walk = {
        items = {
          "player_right_1",
          "player_right_2"
        }
      },

      player_back_walk = {
        items = {
          "player_back_1",
          "player_back_2"
        }
      },

      player_left_walk = {
        items = {
          "player_left_1",
          "player_left_2"
        }
      }
    },
    image_animation_track = {
      player_front_walk = {
        clip = "player_walk",
        sequence = "player_front_walk"
      },

      player_right_walk = {
        clip = "player_walk",
        sequence = "player_right_walk"
      },

      player_back_walk = {
        clip = "player_walk",
        sequence = "player_back_walk"
      },

      player_left_walk = {
        clip = "player_walk",
        sequence = "player_left_walk"
      }
    },
    image_animation_track_set = {
      player_walk = {
        tracks = {
          "player_front_walk",
          "player_right_walk",
          "player_back_walk",
          "player_left_walk"
        }
      }
    },
    directional_image_animation_visual = {
      player_walk = {
        track_set = "player_walk",
        angle_offset = 0
      }
    },
    directional_image_animation_binding = {
      player = {
        entity = "player",
        visual = "player_walk",
        elevation_component = "elevation"
      },
      door_character_test = {
        entity = "door",
        visual = "player_walk"
      },
    },
    directional_image_animation_binding_sequence = {
      projected_characters = {
        items = {
          "player",
          "door_character_test"
        }
      }
    },
    animated_entity_visual_configuration = {
      projected_character_visuals = {
        bindings = "projected_characters"
      }
    },
    physical_material = {
      ball = {
        properties = {
          density = 1,
          restitution = 0.5,
          friction = 0.3
        }
      },

      floor = {
        properties = {
          restitution = 0,
          friction = 0.8
        }
      }
    },

    spatial_levels = {
      main = {
        elevations = {
          0,  -- Level 0: street.
          16, -- Level 1: landing.
          40, -- Level 2: wall.
          64  -- Level 3: rooftop.
        }
      }
    },

    grid_metrics = {
      small_grid = {
        cell_width = 16,
        cell_height = 16
      },

      large_grid = {
        cell_width = 32,
        cell_height = 16
      }
    },

    input_map = {
      default = {
        keys = {
          { action = "interact",       key = "space" },
          { action = "elevation_up",   key = "pageup" },
          { action = "elevation_down", key = "pagedown" },

          { action = "move_up",        key = "w" },
          { action = "move_left",      key = "a" },
          { action = "move_down",      key = "s" },
          { action = "move_right",     key = "d" },

          { action = "turn_left",      key = "q" },
          { action = "turn_right",     key = "e" },

          { action = "step_up",        key = "up" },
          { action = "step_left",      key = "left" },
          { action = "step_down",      key = "down" },
          { action = "step_right",     key = "right" }
        },

        spatial_actions = {
          {
            action = "interact",
            activator_shape = "collision",
            target_shape = "interaction",
            trigger = "interact"
          }
        }
      }
    },

    control_profile = {
      player = {
        vectors = {
          move = {
            x_axis = {
              negative_action = "move_left",
              positive_action = "move_right",
              activation = "down"
            },

            y_axis = {
              negative_action = "move_up",
              positive_action = "move_down",
              activation = "down"
            }
          }
        },

        axes = {
          turn = {
            negative_action = "turn_left",
            positive_action = "turn_right",
            activation = "down"
          },

          elevate = {
            negative_action = "elevation_down",
            positive_action = "elevation_up",
            activation = "down"
          }
        },

        actions = {
          interact = "interact"
        }
      },

      step_player = {
        vectors = {
          move = {
            x_axis = {
              negative_action = "step_left",
              positive_action = "step_right",
              activation = "down"
            },

            y_axis = {
              negative_action = "step_up",
              positive_action = "step_down",
              activation = "down"
            }
          }
        }
      }
    }
  },

  entities = require("project.entity_definitions")
}

return project_definition
