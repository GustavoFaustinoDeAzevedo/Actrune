local Geometry = require("engine.world.spatial.geometry")

local PolygonGeometry = require("engine.world.spatial.polygon_geometry")

local PolygonSweep = {}

local CONTACT_PROBE_DISTANCE = 0.0001

-- Adds a possible polygon sweep contact with its geometric contact point.
local function add_candidate(
    candidates,
    fraction,
    normal_x,
    normal_y,
    point_x,
    point_y
)
  if fraction == nil then
    return
  end

  assert(
    point_x ~= nil and point_y ~= nil,
    "sweep candidate contact point is required"
  )

  table.insert(
    candidates,
    {
      fraction = fraction,

      normal_x = normal_x,
      normal_y = normal_y,

      point_x = point_x,
      point_y = point_y
    }
  )
end

-- Collects contacts produced by moving polygon vertices against target edges.
local function collect_moving_vertex_contacts(
    candidates,
    moving_points,
    target_points,
    move_x,
    move_y,
    target_winding
)
  for moving_index = 1, #moving_points, 2 do
    local point_x = moving_points[moving_index]

    local point_y = moving_points[moving_index + 1]

    for target_index = 1, #target_points, 2 do
      local next_target_index = target_index + 2

      if next_target_index > #target_points then
        next_target_index = 1
      end

      local normal_x, normal_y =
          PolygonGeometry.outward_edge_normal(
            target_points[target_index],
            target_points[target_index + 1],
            target_points[next_target_index],
            target_points[next_target_index + 1],
            target_winding
          )

      if normal_x ~= nil
          and Geometry.dot(
            move_x,
            move_y,
            normal_x,
            normal_y
          ) < -Geometry.EPSILON
      then
        local fraction =
            Geometry.moving_point_segment_fraction(
              point_x,
              point_y,
              move_x,
              move_y,
              target_points[target_index],
              target_points[target_index + 1],
              target_points[next_target_index],
              target_points[next_target_index + 1]
            )

        if fraction ~= nil then
          local contact_x = point_x + move_x * fraction
          local contact_y = point_y + move_y * fraction

          add_candidate(
            candidates,
            fraction,
            normal_x,
            normal_y,
            contact_x,
            contact_y
          )
        end
      end
    end
  end
end

-- Collects contacts produced by target vertices against moving polygon edges.
local function collect_target_vertex_contacts(
    candidates,
    moving_points,
    target_points,
    move_x,
    move_y,
    moving_winding
)
  local relative_x = -move_x
  local relative_y = -move_y

  for target_index = 1, #target_points, 2 do
    local point_x = target_points[target_index]

    local point_y = target_points[target_index + 1]

    for moving_index = 1, #moving_points, 2 do
      local next_moving_index = moving_index + 2

      if next_moving_index > #moving_points then
        next_moving_index = 1
      end

      local outward_x, outward_y =
          PolygonGeometry.outward_edge_normal(
            moving_points[moving_index],
            moving_points[moving_index + 1],
            moving_points[next_moving_index],
            moving_points[next_moving_index + 1],
            moving_winding
          )

      if outward_x ~= nil
          and Geometry.dot(
            relative_x,
            relative_y,
            outward_x,
            outward_y
          ) < -Geometry.EPSILON
      then
        local fraction =
            Geometry.moving_point_segment_fraction(
              point_x,
              point_y,
              relative_x,
              relative_y,
              moving_points[moving_index],
              moving_points[moving_index + 1],
              moving_points[next_moving_index],
              moving_points[next_moving_index + 1]
            )

        if fraction ~= nil then
          add_candidate(
            candidates,
            fraction,
            -outward_x,
            -outward_y,
            point_x,
            point_y
          )
        end
      end
    end
  end
end

-- Returns whether a nearly identical contact normal is already stored.
local function contains_similar_normal(
    normals,
    normal_x,
    normal_y
)
  for _, normal in ipairs(normals) do
    local similarity =
        Geometry.dot(
          normal.x,
          normal.y,
          normal_x,
          normal_y
        )

    if similarity >= 1 - Geometry.EPSILON
    then
      return true
    end
  end

  return false
end



-- Returns whether a nearly identical contact point is already stored.
local function contains_similar_point(
    points,
    point_x,
    point_y
)
  for _, point in ipairs(points) do
    local difference_x = point.x - point_x
    local difference_y = point.y - point_y
    local distance_squared =
        difference_x * difference_x
        + difference_y * difference_y

    if distance_squared <= Geometry.EPSILON * Geometry.EPSILON then
      return true
    end
  end

  return false
end

-- Combines unique normals and contact points produced at the same collision fraction.
local function combine_contact_data(
    candidates,
    fraction
)
  local normals = {}
  local points = {}

  local normal_x = 0
  local normal_y = 0

  local point_x = 0
  local point_y = 0

  local fallback = nil

  for _, candidate in ipairs(candidates) do
    if math.abs(
          candidate.fraction - fraction) <= Geometry.EPSILON
    then
      fallback = fallback or candidate

      if not contains_similar_normal(
            normals,
            candidate.normal_x,
            candidate.normal_y
          )
      then
        table.insert(
          normals,
          {
            x = candidate.normal_x,
            y = candidate.normal_y
          }
        )

        normal_x = normal_x + candidate.normal_x

        normal_y = normal_y + candidate.normal_y
      end

      if not contains_similar_point(
            points,
            candidate.point_x,
            candidate.point_y
          )
      then
        table.insert(
          points,
          {
            x = candidate.point_x,
            y = candidate.point_y
          }
        )

        point_x = point_x + candidate.point_x
        point_y = point_y + candidate.point_y
      end
    end
  end

  local normal_length = math.sqrt(normal_x * normal_x + normal_y * normal_y)

  if fallback and normal_length <= Geometry.EPSILON
  then
    normal_x = fallback.normal_x
    normal_y = fallback.normal_y
  else
    normal_x = normal_x / normal_length
    normal_y = normal_y / normal_length
  end

  if #points > 0 then
    point_x = point_x / #points
    point_y = point_y / #points
  elseif fallback then
    point_x = fallback.point_x
    point_y = fallback.point_y
  end

  return normal_x, normal_y,
      point_x, point_y
end

-- Finds the earliest penetrating contact and combines its simultaneous contact data.
local function find_blocking_candidate(
    candidates,
    moving_points,
    target_points,
    move_x,
    move_y
)
  table.sort(
    candidates,
    function(left, right)
      return left.fraction
          < right.fraction
    end
  )

  local movement_length =
      math.sqrt(
        move_x * move_x
        + move_y * move_y
      )

  if movement_length
      <= Geometry.EPSILON
  then
    return nil
  end

  local probe_fraction =
      CONTACT_PROBE_DISTANCE
      / movement_length

  local blocking_fraction = nil

  for _, candidate in ipairs(candidates) do
    local after_contact =
        candidate.fraction
        + probe_fraction

    local probe_points =
        PolygonGeometry.translate_points(
          moving_points,
          move_x,
          move_y,
          after_contact
        )

    if PolygonGeometry.overlaps_strict(
          probe_points,
          target_points
        ) then
      blocking_fraction =
          candidate.fraction

      break
    end
  end

  if blocking_fraction == nil then
    return nil
  end

  local normal_x,
  normal_y,
  point_x,
  point_y = combine_contact_data(
    candidates,
    blocking_fraction
  )

  return {
    fraction = blocking_fraction,

    normal_x = normal_x,
    normal_y = normal_y,

    point_x = point_x,
    point_y = point_y
  }
end


-- Finds the earliest blocking contact while translating one polygon against another.
function PolygonSweep.sweep(
    moving_shape,
    moving_transform,
    move_x,
    move_y,
    target_shape,
    target_transform
)
  if move_x == 0 and move_y == 0 then
    return nil
  end

  local moving_points =
      moving_shape:get_world_points(
        moving_transform
      )

  local target_points =
      target_shape:get_world_points(
        target_transform
      )

  local moving_winding =
      PolygonGeometry.signed_area(
        moving_points
      )

  local target_winding =
      PolygonGeometry.signed_area(
        target_points
      )

  local candidates = {}

  collect_moving_vertex_contacts(
    candidates,
    moving_points,
    target_points,
    move_x,
    move_y,
    target_winding
  )

  collect_target_vertex_contacts(
    candidates,
    moving_points,
    target_points,
    move_x,
    move_y,
    moving_winding
  )

  return find_blocking_candidate(
    candidates,
    moving_points,
    target_points,
    move_x,
    move_y
  )
end

return PolygonSweep
