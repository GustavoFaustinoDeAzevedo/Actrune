local Geometry =
    require("engine.world.spatial.geometry")

local VelocityMotion = {}

local DEFAULT_MAX_COLLISIONS = 8
local MIN_REMAINING_TIME = 0.0000001

-- Advances a velocity through swept collisions while preserving remaining frame time.
function VelocityMotion.advance(
    spatial_mover,
    velocity,
    dt,
    contact_response,
    options
)
  assert(
    spatial_mover ~= nil,
    "spatial mover is required"
  )

  assert(
    velocity ~= nil,
    "velocity is required"
  )

  options = options or {}

  local max_collisions = options.max_collisions or DEFAULT_MAX_COLLISIONS

  local remaining_time = dt
  local collision_count = 0
  local results = {}

  while remaining_time > MIN_REMAINING_TIME do
    local displacement_x, displacement_y = velocity:get_displacement(remaining_time)

    if math.abs(displacement_x) <= Geometry.EPSILON
        and math.abs(displacement_y) <= Geometry.EPSILON
    then
      break
    end

    local result =
        spatial_mover:try_move(
          displacement_x,
          displacement_y
        )

    table.insert(results, result)

    if not result:has_collision() then
      break
    end

    local contact_fraction = result:get_first_contact_fraction()

    if contact_fraction == nil then
      break
    end

    contact_fraction = Geometry.clamp(contact_fraction, 0, 1)

    remaining_time = remaining_time * (1 - contact_fraction)

    collision_count = collision_count + 1

    if contact_response ~= nil then
      contact_response(
        velocity,
        result
      )
    end

    if collision_count >= max_collisions then
      break
    end
  end

  return results
end

return VelocityMotion
