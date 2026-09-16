-- Holds room events independently of spatial shapes and visual components.
return {
  id = "east_hall_events",

  events = {
    {
      id = "arrival",
      execution_mode = "single",

      pages = {
        {

          -- Keep the southern room active until this execution finishes.
          required_maps = { "south_hall" },

          trigger = {
            type = "signal",
            action = "map_enter"
          },

          commands = {
            { type = "call", action = "map_arrival_started" },
            { type = "wait", duration = 2 },
            { type = "call", action = "map_arrival_finished" }
          }
        }
      }
    }
  }
}
