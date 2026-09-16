local west = require("project.maps.west_hall_entities")
local east = require("project.maps.east_hall_entities")
local shared = require("project.shared_entities")
local south = require("project.maps.south_hall_entities")

-- Preserves existing creation order and appends the southern room's content.
return {
  east.east_hall_events,
  shared.bounce_ball,
  west.floor,
  west.door,
  shared.player,
  west.small_grid_area,
  east.large_grid_area,
  east.free_area,
  shared.step_player,
  south.south_statue
}
