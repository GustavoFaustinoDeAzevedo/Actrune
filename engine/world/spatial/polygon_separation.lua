local Geometry = require("engine.world.spatial.geometry")
local PolygonGeometry = require("engine.world.spatial.polygon_geometry")

local PolygonSeparation = {}

local DEFAULT_INITIAL_DISTANCE = 0.001
local DEFAULT_MAX_DISTANCE = 100000
local DEFAULT_BINARY_ITERATIONS = 24
local DEFAULT_MARGIN = 0.0001
local DIRECTION_EPSILON = 0.000001

-- Returns whether an equivalent separation axis is already stored.
local function contains_direction(directions, x, y)
  for _, direction in ipairs(directions) do
    local similarity = math.abs(Geometry.dot(direction.x, direction.y, x, y))
    if similarity >= 1 - DIRECTION_EPSILON then return true end
  end

  return false
end

-- Collects unique normalized edge normals from a polygon.
local function collect_edge_normals(points, directions)
  for index = 1, #points, 2 do
    local next_index = index + 2
    if next_index > #points then next_index = 1 end

    local edge_x = points[next_index] - points[index]
    local edge_y = points[next_index + 1] - points[index + 1]
    local length = math.sqrt(edge_x * edge_x + edge_y * edge_y)

    if length > Geometry.EPSILON then
      local normal_x = -edge_y / length
      local normal_y = edge_x / length

      if not contains_direction(directions, normal_x, normal_y) then
        table.insert(directions, { x = normal_x, y = normal_y })
      end
    end
  end
end

-- Returns whether translating the first polygon removes its strict overlap with the second.
local function is_separated(points_a, points_b, move_x, move_y)
  local translated = PolygonGeometry.translate_points(points_a, move_x, move_y, 1)
  return not PolygonGeometry.overlaps_strict(translated, points_b)
end

-- Finds the smallest tested distance along one direction that separates two polygons.
local function find_distance(points_a, points_b, direction_x, direction_y, initial_distance, max_distance,
                             binary_iterations)
  local high = math.min(initial_distance, max_distance)

  while high < max_distance and not is_separated(points_a, points_b, direction_x * high, direction_y * high) do
    high = math.min(high * 2, max_distance)
  end

  if not is_separated(points_a, points_b, direction_x * high, direction_y * high) then return nil end

  local low = 0

  for _ = 1, binary_iterations do
    local middle = (low + high) / 2

    if is_separated(points_a, points_b, direction_x * middle, direction_y * middle) then
      high = middle
    else
      low = middle
    end
  end

  return high
end

-- Creates a separation candidate along one directed polygon axis.
local function create_candidate(points_a, points_b, direction_x, direction_y, options)
  local distance = find_distance(
    points_a,
    points_b,
    direction_x,
    direction_y,
    options.initial_distance,
    options.max_distance,
    options.binary_iterations
  )

  if distance == nil then return nil end

  distance = distance + options.margin

  return {
    x = direction_x * distance,
    y = direction_y * distance,
    normal_x = direction_x,
    normal_y = direction_y,
    distance = distance
  }
end

-- Finds the smallest tested translation that removes a strict polygon overlap.
function PolygonSeparation.find(points_a, points_b, options)
  if not PolygonGeometry.overlaps_strict(points_a, points_b) then return nil end

  options = options or {}
  options.initial_distance = options.initial_distance or DEFAULT_INITIAL_DISTANCE
  options.max_distance = options.max_distance or DEFAULT_MAX_DISTANCE
  options.binary_iterations = options.binary_iterations or DEFAULT_BINARY_ITERATIONS
  options.margin = options.margin or DEFAULT_MARGIN

  local directions = {}
  collect_edge_normals(points_a, directions)
  collect_edge_normals(points_b, directions)

  local best = nil

  for _, direction in ipairs(directions) do
    local positive = create_candidate(points_a, points_b, direction.x, direction.y, options)
    local negative = create_candidate(points_a, points_b, -direction.x, -direction.y, options)

    if positive ~= nil and (best == nil or positive.distance < best.distance) then best = positive end
    if negative ~= nil and (best == nil or negative.distance < best.distance) then best = negative end
  end

  return best
end

return PolygonSeparation
