local VelocityResponse = {}

-- Reflects a velocity against a surface normal using a restitution coefficient.
function VelocityResponse.reflect(
    velocity,
    normal_x,
    normal_y,
    restitution
)
  assert(velocity ~= nil, "velocity is required")

  restitution = restitution or 1

  assert(
    restitution >= 0,
    "restitution must be non-negative"
  )

  local normal_length =
      math.sqrt(
        normal_x * normal_x
        + normal_y * normal_y
      )

  if normal_length == 0 then
    return false
  end

  normal_x =
      normal_x / normal_length

  normal_y =
      normal_y / normal_length

  local velocity_x, velocity_y =
      velocity:get()

  local normal_velocity =
      velocity_x * normal_x
      + velocity_y * normal_y

  if normal_velocity >= 0 then
    return false
  end

  local response =
      (1 + restitution)
      * normal_velocity

  velocity:set(
    velocity_x
    - response * normal_x,

    velocity_y
    - response * normal_y
  )

  return true
end

return VelocityResponse
