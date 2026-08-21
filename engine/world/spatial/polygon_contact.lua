local Geometry = require("engine.world.spatial.geometry")

local PolygonContact = {}

local DEFAULT_SLOP = 0.01
local NORMAL_SIMILARITY = 0.999999

-- Returns the average position of a polygon's vertices.
local function get_center(points)
  local x, y = 0, 0
  local count = #points / 2

  for index = 1, #points, 2 do
    x = x + points[index]
    y = y + points[index + 1]
  end

  return x / count, y / count
end

-- Returns the closest point on a segment to the provided point.
local function closest_point_on_segment(point_x, point_y, start_x, start_y, end_x, end_y)
  local segment_x = end_x - start_x
  local segment_y = end_y - start_y
  local length_squared = segment_x * segment_x + segment_y * segment_y

  if length_squared <= Geometry.EPSILON then return start_x, start_y end

  local offset_x = point_x - start_x
  local offset_y = point_y - start_y
  local fraction = Geometry.clamp((offset_x * segment_x + offset_y * segment_y) / length_squared, 0, 1)

  return start_x + segment_x * fraction, start_y + segment_y * fraction
end

-- Orients a normal from polygon B toward polygon A.
local function orient_normal(normal_x, normal_y, center_a_x, center_a_y, center_b_x, center_b_y)
  local direction_x = center_a_x - center_b_x
  local direction_y = center_a_y - center_b_y

  if Geometry.dot(normal_x, normal_y, direction_x, direction_y) < 0 then
    return -normal_x, -normal_y
  end

  return normal_x, normal_y
end

-- Creates a closest-feature contact candidate.
local function create_candidate(point_x, point_y, closest_x, closest_y, edge_x, edge_y, center_a_x, center_a_y,
                                center_b_x, center_b_y)
  local difference_x = point_x - closest_x
  local difference_y = point_y - closest_y
  local distance_squared = difference_x * difference_x + difference_y * difference_y

  local normal_x, normal_y

  if distance_squared > Geometry.EPSILON * Geometry.EPSILON then
    local distance = math.sqrt(distance_squared)
    normal_x = difference_x / distance
    normal_y = difference_y / distance
  else
    local edge_length = math.sqrt(edge_x * edge_x + edge_y * edge_y)
    if edge_length <= Geometry.EPSILON then return nil end

    normal_x = -edge_y / edge_length
    normal_y = edge_x / edge_length
    normal_x, normal_y = orient_normal(normal_x, normal_y, center_a_x, center_a_y, center_b_x, center_b_y)
  end

  return {
    distance_squared = distance_squared,
    normal_x = normal_x,
    normal_y = normal_y,
    point_x = (point_x + closest_x) / 2,
    point_y = (point_y + closest_y) / 2
  }
end

-- Collects vertex-to-edge contact candidates from polygon A against polygon B.
local function collect_candidates(points_a, points_b, candidates, reverse)
  local center_a_x, center_a_y = get_center(points_a)
  local center_b_x, center_b_y = get_center(points_b)

  for point_index = 1, #points_a, 2 do
    local point_x = points_a[point_index]
    local point_y = points_a[point_index + 1]

    for edge_index = 1, #points_b, 2 do
      local next_index = edge_index + 2
      if next_index > #points_b then next_index = 1 end

      local start_x = points_b[edge_index]
      local start_y = points_b[edge_index + 1]
      local end_x = points_b[next_index]
      local end_y = points_b[next_index + 1]
      local closest_x, closest_y = closest_point_on_segment(point_x, point_y, start_x, start_y, end_x, end_y)

      local candidate = create_candidate(
        point_x, point_y, closest_x, closest_y,
        end_x - start_x, end_y - start_y,
        center_a_x, center_a_y, center_b_x, center_b_y
      )

      if candidate ~= nil then
        if reverse then
          candidate.normal_x = -candidate.normal_x
          candidate.normal_y = -candidate.normal_y
        end

        table.insert(candidates, candidate)
      end
    end
  end
end

-- Returns whether an equivalent normal is already stored.
local function contains_normal(normals, normal_x, normal_y)
  for _, normal in ipairs(normals) do
    if Geometry.dot(normal.x, normal.y, normal_x, normal_y) >= NORMAL_SIMILARITY then return true end
  end

  return false
end

-- Finds the closest persistent contact between two polygons.
function PolygonContact.find(points_a, points_b, slop)
  slop = slop or DEFAULT_SLOP

  local candidates = {}
  collect_candidates(points_a, points_b, candidates, false)
  collect_candidates(points_b, points_a, candidates, true)

  local minimum_squared = nil

  for _, candidate in ipairs(candidates) do
    if minimum_squared == nil or candidate.distance_squared < minimum_squared then minimum_squared = candidate
      .distance_squared end
  end

  if minimum_squared == nil or minimum_squared > slop * slop then return nil end

  local normals = {}
  local normal_x, normal_y = 0, 0
  local point_x, point_y = 0, 0
  local count = 0
  local tolerance = Geometry.EPSILON * Geometry.EPSILON

  for _, candidate in ipairs(candidates) do
    if candidate.distance_squared <= minimum_squared + tolerance then
      if not contains_normal(normals, candidate.normal_x, candidate.normal_y) then
        table.insert(normals, { x = candidate.normal_x, y = candidate.normal_y })
        normal_x = normal_x + candidate.normal_x
        normal_y = normal_y + candidate.normal_y
      end

      point_x = point_x + candidate.point_x
      point_y = point_y + candidate.point_y
      count = count + 1
    end
  end

  local length = math.sqrt(normal_x * normal_x + normal_y * normal_y)
  if length <= Geometry.EPSILON then return nil end

  return {
    normal_x = normal_x / length,
    normal_y = normal_y / length,
    point_x = point_x / count,
    point_y = point_y / count,
    distance = math.sqrt(minimum_squared)
  }
end

return PolygonContact
