local Geometry = require("engine.world.spatial.geometry")

local PolygonGeometry = require("engine.world.spatial.polygon_geometry")

local PolygonSweep = {}

local CONTACT_PROBE_DISTANCE = 0.0001

-- Adds a possible polygon sweep contact to a candidate list.
local function add_candidate(
    candidates,
    fraction,
    normal_x,
    normal_y
)
  if fraction == nil then
    return
  end

  table.insert(
    candidates,
    {
      fraction = fraction,
      normal_x = normal_x,
      normal_y = normal_y
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

        add_candidate(
          candidates,
          fraction,
          normal_x,
          normal_y
        )
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

      if outward_x ~= nil and Geometry.dot(
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

        add_candidate(candidates, fraction, -outward_x, -outward_y)
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

    if similarity
        >= 1 - Geometry.EPSILON
    then
      return true
    end
  end

  return false
end

-- Combines unique normals produced at the same collision fraction.
local function combine_contact_normals(
    candidates,
    fraction
)
  local normals = {}

  local combined_x = 0
  local combined_y = 0

  local fallback = nil

  for _, candidate in ipairs(candidates) do
    if math.abs(candidate.fraction - fraction) <= Geometry.EPSILON
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

        combined_x = combined_x + candidate.normal_x

        combined_y = combined_y + candidate.normal_y
      end
    end
  end

  local combined_length = math.sqrt(
    combined_x * combined_x
    + combined_y * combined_y
  )

  if fallback and combined_length <= Geometry.EPSILON
  then
    return fallback.normal_x, fallback.normal_y
  end

  return combined_x / combined_length,
      combined_y / combined_length
end

-- Finds the earliest penetrating contact and combines its simultaneous surface normals.
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

  local movement_length = math.sqrt(move_x * move_x + move_y * move_y)

  if movement_length <= Geometry.EPSILON
  then
    return nil
  end

  local probe_fraction =
      CONTACT_PROBE_DISTANCE
      / movement_length

  local blocking_fraction = nil

  for _, candidate in ipairs(candidates) do
    local after_contact = candidate.fraction + probe_fraction
    local probe_points =
        PolygonGeometry.translate_points(
          moving_points,
          move_x,
          move_y,
          after_contact
        )

    if PolygonGeometry.overlaps_strict(probe_points, target_points) then
      blocking_fraction = candidate.fraction

      break
    end
  end

  if blocking_fraction == nil then
    return nil
  end

  local normal_x, normal_y =
      combine_contact_normals(
        candidates,
        blocking_fraction
      )

  return {
    fraction = blocking_fraction,
    normal_x = normal_x,
    normal_y = normal_y
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
