-- Declares map-owned entity data for composition by the project loader.
local definitions = {
  -- Defines the static physics surface.
  floor = {
    id = "floor",
    transform = { x = 320, y = 480 },

    shapes = {
      physics = {
        type = "polygon",
        material = "floor",
        points = {
          { x = -250, y = -20 },
          { x = -80, y = -20 },
          { x = -40, y = -70 },
          { x = 0, y = -20 },
          { x = 250, y = -20 },
          { x = 250, y = 20 },
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

  -- Defines the obstacle and its directional interaction event.
  door = {
    id = "door",
    transform = { x = 200, y = 150 },

    shapes = {
      interaction = {
        type = "polygon",
        points = {
          { x = -50, y = -40 },
          { x = 50, y = -40 },
          { x = 50, y = 40 },
          { x = -50, y = 40 }
        }
      },
      collision = {
        type = "polygon",
        points = {
          { x = -20, y = -40 },
          { x = 20, y = -40 },
          { x = 20, y = 40 },
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
              enabled = true,
              action = "interact",
              shape = "interaction",
              activator_shape = "collision",
              max_angle = math.rad(60),
              vertical_mode = "overlap",
              target_vertical_range = "interaction_height",
              activator_vertical_range = "interaction_height"
            },
            commands = {
              { type = "call", action = "test_event_started" },
              { type = "wait", duration = 2 },
              { type = "call", action = "test_event_finished" }
            }
          }
        }
      }
    }
  },

  -- Defines the region that supplies the small-grid movement context.
  small_grid_area = {
    id = "small_grid_area",
    transform = { x = 400, y = 200 },

    shapes = {
      area = {
        type = "polygon",
        points = {
          { x = -100, y = -100 },
          { x = 100, y = -100 },
          { x = 100, y = 100 },
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
  }
}

return definitions