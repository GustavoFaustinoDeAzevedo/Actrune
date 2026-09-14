local west = require("project.maps.west_hall_entities")
local east = require("project.maps.east_hall_entities")
local shared = require("project.shared_entities")

-- Composes existing definitions in explicit entity creation order.
return {
  east.east_hall_events,
  shared.bounce_ball,
  west.floor,
  west.door,
  shared.player,
  west.small_grid_area,
  east.large_grid_area,
  east.free_area,
  shared.step_player
}
