-- Declares the eastern room bounds and its authored entity membership.
---@type MapRegionDefinition
local definition = {
  min_x = 512,
  min_y = 0,
  max_x = 1024,
  max_y = 768,
  entities = { "large_grid_area", "free_area", "east_hall_events" }
}

return definition