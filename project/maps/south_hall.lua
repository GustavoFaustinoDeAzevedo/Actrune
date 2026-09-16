-- Declares the southern room and the entity whose state survives suspension.
---@type MapRegionDefinition
local definition = {
  min_x = 512,
  min_y = 768,
  max_x = 1024,
  max_y = 1536,
  entities = { "south_statue" },
  neighbors = { "east_hall" }
}

return definition
