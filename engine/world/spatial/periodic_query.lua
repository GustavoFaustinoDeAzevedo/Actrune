local Geometry = require("engine.world.spatial.geometry")
local Transform = require("engine.world.transform")

local PeriodicQuery = {}

--- Returns image indices whose translated interval touches the query interval.
---@param query_min number Lower query coordinate.
---@param query_max number Upper query coordinate.
---@param target_min number Original target lower coordinate.
---@param target_max number Original target upper coordinate.
---@param period? number Repetition distance; nil selects the original image only.
---@return integer first First index; greater than last for an empty range.
---@return integer last Last index.
function PeriodicQuery.get_axis_range(query_min, query_max, target_min, target_max, period)
  if period == nil then
    if query_max < target_min - Geometry.EPSILON
        or query_min > target_max + Geometry.EPSILON then
      return 1, 0
    end
    return 0, 0
  end

  return math.ceil((query_min - target_max - Geometry.EPSILON) / period),
      math.floor((query_max - target_min + Geometry.EPSILON) / period)
end

--- Encloses transformed geometry, including shape offsets and analytic circles.
---@param shape table Shape exposing get_world_points or circle geometry.
---@param transform Transform Original shape transform.
---@return SpatialBounds bounds World-space enclosure.
function PeriodicQuery.get_bounds(shape, transform)
  local points

  if type(shape.get_geometry_type) == "function" and shape:get_geometry_type() == "circle" then
    local x, y = shape:get_offset()
    local radius = shape:get_radius()
    points = {}

    for _, corner in ipairs({
      { x - radius, y - radius }, { x + radius, y - radius },
      { x + radius, y + radius }, { x - radius, y + radius }
    }) do
      local wx, wy = transform:transform_point(corner[1], corner[2])
      points[#points + 1], points[#points + 2] = wx, wy
    end
  else
    points = shape:get_world_points(transform)
  end

  local a, b, c, d = points[1], points[2], points[1], points[2]

  for index = 3, #points, 2 do
    a, b = math.min(a, points[index]), math.min(b, points[index + 1])
    c, d = math.max(c, points[index]), math.max(d, points[index + 1])
  end

  return { min_x = a, min_y = b, max_x = c, max_y = d }
end

--- Visits all images touching the query bounds; original transforms remain unchanged.
---@param topology WorldTopology Enabled axes and map periods.
---@param bounds SpatialBounds Query bounds in the source coordinate frame.
---@param shape table Target shape.
---@param transform Transform Original target transform.
---@param visitor fun(image: Transform): boolean? Return true to stop visiting.
---@return boolean stopped Whether a callback requested early termination.
function PeriodicQuery.visit_transforms(topology, bounds, shape, transform, visitor)
  local target = PeriodicQuery.get_bounds(shape, transform)

  local first_x, last_x = PeriodicQuery.get_axis_range(
    bounds.min_x, bounds.max_x, target.min_x, target.max_x,
    topology.loop_x and topology.width or nil
  )

  local first_y, last_y = PeriodicQuery.get_axis_range(
    bounds.min_y, bounds.max_y, target.min_y, target.max_y,
    topology.loop_y and topology.height or nil
  )

  for column = first_x, last_x do
    for row = first_y, last_y do
      local image = transform

      if column ~= 0 or row ~= 0 then
        image = Transform.new({
          x = transform.x + column * topology.width,
          y = transform.y + row * topology.height,
          rotation = transform.rotation,
          scale_x = transform.scale_x,
          scale_y = transform.scale_y
        })
      end

      if visitor(image) == true then return true end
    end
  end

  return false
end

return PeriodicQuery
