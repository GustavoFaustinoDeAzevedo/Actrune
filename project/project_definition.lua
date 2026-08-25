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
      }
    }
  }
}

return project_definition
