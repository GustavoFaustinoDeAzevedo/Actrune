local project_definition = {
  resources = {

    test_scene_render_configuration = {
      main = {
        render_mode = "orthographic",
        orthographic_elevation_scale = 1,

        world_camera_target_entity = "player",
        projected_camera_target_entity = "player",

        world_camera_position_half_life = 0.08,
        projected_camera_position_half_life = 0.08,
        projected_camera_rotation_half_life = 0.1,
        projected_camera_forward_offset = -96,
        camera_elevation = 32,
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
          { action = "interact",   key = "space" },

          { action = "move_up",    key = "w" },
          { action = "move_left",  key = "a" },
          { action = "move_down",  key = "s" },
          { action = "move_right", key = "d" },

          { action = "turn_left",  key = "q" },
          { action = "turn_right", key = "e" },

          { action = "step_up",    key = "up" },
          { action = "step_left",  key = "left" },
          { action = "step_down",  key = "down" },
          { action = "step_right", key = "right" }
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

  entities = {
    {
      id = "bounce_ball",

      transform = {
        x = 280,
        y = 200
      },

      shapes = {
        physics = {
          type = "circle",
          radius = 10,
          material = "ball"
        }
      },

      components = {
        rigid_body = {
          type = "rigid_body",
          body_type = "dynamic",
          shapes = { "physics" }
        }
      }
    },

    {
      id = "floor",

      transform = {
        x = 320,
        y = 480
      },

      shapes = {
        physics = {
          type = "polygon",
          material = "floor",

          points = {
            { x = -250, y = -20 },
            { x = -80,  y = -20 },
            { x = -40,  y = -70 },
            { x = 0,    y = -20 },
            { x = 250,  y = -20 },
            { x = 250,  y = 20 },
            { x = -250, y = 20 }
          }
        }
      },

      components = {
        rigid_body = {
          type = "rigid_body",
          body_type = "static",
          shapes = { "physics" }
        }
      }
    },

    {
      id = "door",

      transform = {
        x = 200,
        y = 150
      },

      shapes = {
        interaction = {
          type = "polygon",

          points = {
            { x = -50, y = -40 },
            { x = 50,  y = -40 },
            { x = 50,  y = 40 },
            { x = -50, y = 40 }
          }
        },

        collision = {
          type = "polygon",

          points = {
            { x = -20, y = -40 },
            { x = 20,  y = -40 },
            { x = 20,  y = 40 },
            { x = -20, y = 40 }
          }
        }
      },

      components = {
        interaction_height = {
          type = "vertical_range",
          lower = 0,
          upper = 12
        },
        collision_height = {
          type = "vertical_range",
          lower = 0,
          upper = 12
        },
      },

      events = {
        {
          id = "test_event",
          execution_mode = "single",

          pages = {
            {
              trigger = {
                type = "directional_area",
                enabled = false,
                action = "interact",
                shape = "interaction",
                activator_shape = "collision",
                max_angle = math.rad(60),
                vertical_mode = "overlap",
                target_vertical_range = "interaction_height",
                activator_vertical_range = "interaction_height"
              },

              commands = {
                {
                  type = "call",
                  action = "test_event_started"
                },

                {
                  type = "wait",
                  duration = 2
                },

                {
                  type = "call",
                  action = "test_event_finished"
                }
              }
            }
          }
        }
      }
    },

    {
      id = "player",

      transform = {
        x = 260,
        y = 150,
        rotation = math.rad(270)
      },

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
        controls = {
          type = "controls",
          profile = "player"
        },

        movement_direction = {
          type = "facing_direction"
        },

        rotation_control = {
          type = "rotation_control",
          controls = "controls",
          input = "turn",

          amount = {
            type = "value",
            value = math.rad(90)
          },

          application = {
            type = "on_activation"
          },

          control_order = 10
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

              value = {
                type = "value",
                value = 120
              }
            }
          },

          application = {
            type = "while_active"
          },

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

    {
      id = "small_grid_area",

      transform = {
        x = 400,
        y = 200
      },

      shapes = {
        area = {
          type = "polygon",

          points = {
            { x = -100, y = -100 },
            { x = 100,  y = -100 },
            { x = 100,  y = 100 },
            { x = -100, y = 100 }
          }
        }
      },

      components = {
        grid_area = {
          type = "grid_area",
          shape = "area",
          metrics = "small_grid",
          priority = 0
        }
      }
    },

    {
      id = "large_grid_area",

      transform = {
        x = 600,
        y = 200
      },

      shapes = {
        area = {
          type = "polygon",

          points = {
            { x = -100, y = -100 },
            { x = 100,  y = -100 },
            { x = 100,  y = 100 },
            { x = -100, y = 100 }
          }
        }
      },

      components = {
        grid_area = {
          type = "grid_area",
          shape = "area",
          metrics = "large_grid",
          priority = 10
        }
      }
    },

    {
      id = "free_area",

      transform = {
        x = 800,
        y = 200
      },

      shapes = {
        area = {
          type = "polygon",

          points = {
            { x = -100, y = -100 },
            { x = 100,  y = -100 },
            { x = 100,  y = 100 },
            { x = -100, y = 100 }
          }
        }
      },

      components = {
        grid_area = {
          type = "grid_area",
          shape = "area",
          priority = 20
        }
      }
    },

    {
      id = "step_player",

      transform = {
        x = 450,
        y = 150
      },

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
        controls = {
          type = "controls",
          profile = "step_player"
        },

        grid_context = {
          type = "grid_context",
          metrics = "small_grid"
        },

        movement_direction = {
          type = "facing_direction"
        },

        grid_translation = {
          type = "translation_control",
          controls = "controls",
          input = "move",
          direction = "movement_direction",
          source_vertical_range = "collision_height",
          target_vertical_range = "collision_height",

          direction_policy = {
            type = "last_changed_axis",
            initial_axis = "x"
          },

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

            application = {
              type = "on_change",
              fields = { "input_x", "input_y" }
            }
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

          direction_policy = {
            type = "last_changed_axis",
            initial_axis = "x"
          },

          displacement = {
            type = "uniform",

            amount = {
              type = "delta_time",

              value = {
                type = "value",
                value = 120
              }
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

            application = {
              type = "while_active"
            }
          },

          source_shape = "collision",
          target_shape = "collision",
          control_order = 20
        }
      }
    }
  }
}

return project_definition
