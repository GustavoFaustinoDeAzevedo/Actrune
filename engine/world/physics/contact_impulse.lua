local Geometry =
    require("engine.world.spatial.geometry")

local ContactImpulse = {}

-- Applies restitution and Coulomb friction impulses against an immovable contact surface.
function ContactImpulse.apply(
    velocity,
    mass,
    normal_x,
    normal_y,
    properties
)
  assert(velocity ~= nil, "velocity is required")
  assert(mass ~= nil, "mass is required")

  properties = properties or {}

  local restitution = properties.restitution or 0
  local static_friction = properties.static_friction or 0
  local dynamic_friction = properties.dynamic_friction or 0
  local normal_length = math.sqrt(normal_x * normal_x + normal_y * normal_y)

  if normal_length <= Geometry.EPSILON then
    return false
  end

  normal_x = normal_x / normal_length

  normal_y = normal_y / normal_length

  local velocity_x, velocity_y = velocity:get()

  local normal_velocity =
      Geometry.dot(
        velocity_x,
        velocity_y,
        normal_x,
        normal_y
      )

  if normal_velocity >= 0 then
    return false
  end

  local inverse_mass = mass:get_inverse()
  local normal_impulse = -(1 + restitution) * normal_velocity / inverse_mass
  local tangent_x = velocity_x - normal_velocity * normal_x
  local tangent_y = velocity_y - normal_velocity * normal_y
  local tangent_length = math.sqrt(tangent_x * tangent_x + tangent_y * tangent_y)
  local tangent_impulse = 0

  if tangent_length > Geometry.EPSILON then
    tangent_x =
        tangent_x / tangent_length

    tangent_y =
        tangent_y / tangent_length

    local tangent_velocity =
        Geometry.dot(
          velocity_x,
          velocity_y,
          tangent_x,
          tangent_y
        )

    tangent_impulse = -tangent_velocity / inverse_mass

    local maximum_static_impulse = static_friction * normal_impulse

    if math.abs(tangent_impulse) > maximum_static_impulse
    then
      local direction = 1

      if tangent_velocity < 0 then
        direction = -1
      end

      tangent_impulse = -direction * dynamic_friction * normal_impulse
    end
  end

  local impulse_x = normal_impulse * normal_x + tangent_impulse * tangent_x
  local impulse_y = normal_impulse * normal_y + tangent_impulse * tangent_y

  velocity:add(
    impulse_x * inverse_mass,
    impulse_y * inverse_mass
  )

  return true
end

return ContactImpulse
