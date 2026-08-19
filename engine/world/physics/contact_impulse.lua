local Geometry =
    require("engine.world.spatial.geometry")

local ContactImpulse = {}

-- Returns the inverse mass of an optional dynamic body.
local function get_inverse_mass(mass)
  if mass == nil then
    return 0
  end

  return mass:get_inverse()
end

-- Returns the velocity components of an optional dynamic body.
local function get_velocity(velocity)
  if velocity == nil then
    return 0, 0
  end

  return velocity:get()
end

-- Applies an impulse to an optional dynamic body.
local function apply_impulse(
    velocity,
    inverse_mass,
    impulse_x,
    impulse_y
)
  if velocity == nil
      or inverse_mass == 0
  then
    return
  end

  velocity:add(
    impulse_x * inverse_mass,
    impulse_y * inverse_mass
  )
end

-- Applies restitution and Coulomb friction impulses between two physical bodies.
function ContactImpulse.apply_pair(
    source_velocity,
    source_mass,
    target_velocity,
    target_mass,
    normal_x,
    normal_y,
    properties
)
  assert(
    source_velocity ~= nil,
    "source velocity is required"
  )

  assert(
    source_mass ~= nil,
    "source mass is required"
  )

  assert(
    (target_velocity == nil)
    == (target_mass == nil),
    "target velocity and mass must both be present or absent"
  )

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

  local source_x, source_y = get_velocity(source_velocity)
  local target_x, target_y = get_velocity(target_velocity)
  local relative_x = source_x - target_x
  local relative_y = source_y - target_y
  local normal_velocity =
      Geometry.dot(
        relative_x,
        relative_y,
        normal_x,
        normal_y
      )

  if normal_velocity >= 0 then
    return false
  end

  local source_inverse_mass = get_inverse_mass(source_mass)
  local target_inverse_mass = get_inverse_mass(target_mass)
  local inverse_mass_sum = source_inverse_mass + target_inverse_mass

  if inverse_mass_sum <= Geometry.EPSILON then
    return false
  end

  local normal_impulse =
      -(1 + restitution) * normal_velocity
      / inverse_mass_sum

  local tangent_x = relative_x - normal_velocity * normal_x
  local tangent_y = relative_y - normal_velocity * normal_y
  local tangent_length =
      math.sqrt(tangent_x * tangent_x + tangent_y * tangent_y)

  local tangent_impulse = 0

  if tangent_length > Geometry.EPSILON then
    tangent_x = tangent_x / tangent_length
    tangent_y = tangent_y / tangent_length

    local tangent_velocity =
        Geometry.dot(
          relative_x,
          relative_y,
          tangent_x,
          tangent_y
        )

    tangent_impulse = -tangent_velocity / inverse_mass_sum

    local static_limit = static_friction * normal_impulse

    if math.abs(tangent_impulse) > static_limit
    then
      local tangent_sign = 1

      if tangent_velocity < 0 then
        tangent_sign = -1
      end

      tangent_impulse = -tangent_sign * dynamic_friction * normal_impulse
    end
  end

  local impulse_x = normal_x * normal_impulse + tangent_x * tangent_impulse
  local impulse_y = normal_y * normal_impulse + tangent_y * tangent_impulse

  apply_impulse(
    source_velocity,
    source_inverse_mass,
    impulse_x,
    impulse_y
  )

  apply_impulse(
    target_velocity,
    target_inverse_mass,
    -impulse_x,
    -impulse_y
  )

  return true
end

-- Applies contact impulses between a dynamic body and an immovable surface.
function ContactImpulse.apply(
    velocity,
    mass,
    normal_x,
    normal_y,
    properties
)
  return ContactImpulse.apply_pair(
    velocity,
    mass,
    nil,
    nil,
    normal_x,
    normal_y,
    properties
  )
end

return ContactImpulse
