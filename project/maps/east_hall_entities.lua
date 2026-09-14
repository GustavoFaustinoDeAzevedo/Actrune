-- Declares map-owned entity data for composition by the project loader.
local definitions = {
  -- Reuses the dedicated room-event definition.
  east_hall_events = require("project.maps.east_hall_events"),

  -- Defines the region that supplies the large-grid movement context.
  large_grid_area = {
    id = "large_grid_area",
    transform = { x = 600, y = 200 },

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

  -- Defines the higher-priority region that selects free movement.
  free_area = {
    id = "free_area",
    transform = { x = 800, y = 200 },

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
  }
}

return definitions
