local project_definition = {
  resources = {
    physical_material = {
      ball = {
        properties = {
          density = 1,
          restitution = 0.6,
          friction = 0.3
        }
      },

      floor = {
        properties = {
          restitution = 0.2,
          friction = 0.8
        }
      }
    },

    grid_metrics = {
      test_grid = {
        cell_size = 16
      },

      large_grid = {
        cell_size = 32
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
        x = 320,
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

      events = {
        {
          id = "test_event",
          execution_mode = "single",

          pages = {
            {
              trigger = {
                type = "directional_area",
                action = "interact",
                shape = "interaction",
                activator_shape = "collision",
                max_angle = math.rad(60)
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

          amount = {
            type = "delta_time",

            value = {
              type = "value",
              value = 120
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
      id = "step_player",

      transform = {
        x = 450,
        y = 150
      },

      shapes = {
        collision = {
          type = "polygon",

          points = {
            { x = -10, y = -10 },
            { x = 10,  y = -10 },
            { x = 10,  y = 10 },
            { x = -10, y = 10 }
          }
        }
      },

      components = {
        controls = {
          type = "controls",
          profile = "step_player"
        },

        grid_context = {
          type = "grid_context",
          metrics = "large_grid"
        },

        movement_direction = {
          type = "facing_direction"
        },

        translation_control = {
          type = "translation_control",
          controls = "controls",
          input = "move",
          direction = "movement_direction",

          amount = {
            type = "component_property",
            component = "grid_context",
            property = "cell_size"
          },

          application = {
            type = "on_activation"
          },

          source_shape = "collision",
          target_shape = "collision",
          control_order = 10
        }
      }
    }
  }
}

return project_definition
