-- Declares the western room bounds, content and residency neighbors.
---@type MapRegionDefinition
local definition = {
  min_x = 0,
  min_y = 0,
  max_x = 512,
  max_y = 768,
  entities = { "floor", "door", "small_grid_area" },
  neighbors = { "east_hall" }
}

return definition
