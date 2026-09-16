-- Declares the southern room's persistent interaction test.
local definitions = {
  south_statue = {
    id = "south_statue",
    transform = { x = 768, y = 1050 },

    shapes = {
      interaction = {
        type = "polygon",
        points = {
          { x = -48, y = -48 },
          { x = 48,  y = -48 },
          { x = 48,  y = 48 },
          { x = -48, y = 48 }
        }
      }
    },

    components = {
      elevation = {
        type = "spatial_elevation",
        levels = "main",
        level = 0,
        offset = 0
      }
    },

    events = {
      {
        id = "raise_statue",
        execution_mode = "single",
        pages = {
          {
            -- This test accepts nearby interaction from any facing or elevation.
            trigger = {
              type = "directional_area",
              action = "interact",
              shape = "interaction",
              activator_shape = "collision",
              max_angle = math.pi,
              vertical_mode = "ignore"
            },
            commands = {
              { type = "call", action = "raise_south_statue" }
            }
          }
        }
      }
    }
  }
}

return definitions
