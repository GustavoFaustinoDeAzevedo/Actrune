local Geometry = require("engine.world.spatial.geometry")

local PolygonGeometry = {}

-- Calculates the signed area used to determine a polygon's winding direction.
function PolygonGeometry.signed_area(points)
  local area = 0

  for index = 1, #points, 2 do
    local next_index = index + 2

    if next_index > #points then
      next_index = 1
    end

    area = area
        + points[index]
        * points[next_index + 1]
        - points[next_index]
        * points[index + 1]
  end

  return area * 0.5
end

-- Calculates the outward unit normal of a polygon edge.
function PolygonGeometry.outward_edge_normal(
    start_x,
    start_y,
    end_x,
    end_y,
    winding
)
  local edge_x = end_x - start_x

  local edge_y = end_y - start_y

  local length = math.sqrt(edge_x * edge_x + edge_y * edge_y)

  if length <= Geometry.EPSILON then
    return nil, nil
  end

  if winding >= 0 then
    return edge_y / length, -edge_x / length
  end

  return -edge_y / length, edge_x / length
end

-- Returns whether a point lies strictly inside a polygon and not on its boundary.
function PolygonGeometry.point_strictly_inside(point_x, point_y, points)
  local inside = false

  for index = 1, #points, 2 do
    local next_index = index + 2

    if next_index > #points
    then
      next_index = 1
    end

    local start_x = points[index]

    local start_y = points[index + 1]

    local end_x = points[next_index]

    local end_y = points[next_index + 1]

    if Geometry.point_on_segment(
          point_x,
          point_y,
          start_x,
          start_y,
          end_x,
          end_y
        ) then
      return false
    end

    local crosses_y = (start_y > point_y) ~= (end_y > point_y)

    if crosses_y then
      local intersection_x =
          (end_x - start_x) * (point_y - start_y)
          / (end_y - start_y) + start_x

      if point_x < intersection_x then
        inside = not inside
      end
    end
  end

  return inside
end

-- Returns whether two simple polygons have overlapping interior areas.
function PolygonGeometry.overlaps_strict(points_a, points_b)
  local winding_a = PolygonGeometry.signed_area(points_a)
  local winding_b = PolygonGeometry.signed_area(points_b)
  local same_winding = (winding_a > 0) == (winding_b > 0)

  for index_a = 1, #points_a, 2 do
    local next_a = index_a + 2
    if next_a > #points_a then next_a = 1 end

    local ax, ay = points_a[index_a], points_a[index_a + 1]
    local bx, by = points_a[next_a], points_a[next_a + 1]
    local edge_x, edge_y = bx - ax, by - ay

    for index_b = 1, #points_b, 2 do
      local next_b = index_b + 2
      if next_b > #points_b then next_b = 1 end

      local cx, cy = points_b[index_b], points_b[index_b + 1]
      local dx, dy = points_b[next_b], points_b[next_b + 1]

      if Geometry.segments_properly_intersect(ax, ay, bx, by, cx, cy, dx, dy) then
        return true
      end

      -- Shared edges imply overlap only when both interiors lie on the same side.
      local dot = Geometry.dot(edge_x, edge_y, dx - cx, dy - cy)

      if dot ~= 0 and ((dot > 0) == same_winding)
          and math.abs(Geometry.cross(ax, ay, bx, by, cx, cy)) <= Geometry.EPSILON
          and math.abs(Geometry.cross(ax, ay, bx, by, dx, dy)) <= Geometry.EPSILON then
        local overlap

        if math.abs(edge_x) >= math.abs(edge_y) then
          overlap = math.min(math.max(ax, bx), math.max(cx, dx))
              - math.max(math.min(ax, bx), math.min(cx, dx))
        else
          overlap = math.min(math.max(ay, by), math.max(cy, dy))
              - math.max(math.min(ay, by), math.min(cy, dy))
        end

        if overlap > Geometry.EPSILON then return true end
      end
    end
  end

  for index = 1, #points_a, 2 do
    if PolygonGeometry.point_strictly_inside(points_a[index], points_a[index + 1], points_b) then
      return true
    end
  end

  for index = 1, #points_b, 2 do
    if PolygonGeometry.point_strictly_inside(points_b[index], points_b[index + 1], points_a) then
      return true
    end
  end

  return false
end

-- Creates a translated copy of polygon points using a displacement fraction.
function PolygonGeometry.translate_points(
    points,
    dx,
    dy,
    fraction
)
  local translated = {}

  for index = 1, #points, 2 do
    table.insert(
      translated,
      points[index]
      + dx * fraction
    )

    table.insert(
      translated,
      points[index + 1]
      + dy * fraction
    )
  end

  return translated
end

return PolygonGeometry
