local Geometry = require("engine.world.spatial.geometry")
local AngularImpulse = require("engine.world.physics.angular_impulse")

local ContactImpulse = {}

-- Returns the inverse mass of an optional dynamic body.
local function get_inverse_mass(mass)
  if mass == nil then return 0 end
  return mass:get_inverse()
end

-- Returns the linear velocity of an optional dynamic body.
local function get_linear_velocity(velocity)
  if velocity == nil then return 0, 0 end
  return velocity:get()
end

-- Returns the optional angular body's contribution to velocity at the contact point.
local function get_angular_point_velocity(angular, point_x, point_y)
  if angular == nil then return 0, 0 end

  return AngularImpulse.get_point_velocity(
    angular.angular_velocity,
    angular.center_x,
    angular.center_y,
    point_x,
    point_y
  )
end

-- Returns the complete velocity of a body at the contact point.
local function get_contact_velocity(velocity, angular, point_x, point_y)
  local linear_x, linear_y = get_linear_velocity(velocity)
  local angular_x, angular_y = get_angular_point_velocity(angular, point_x, point_y)

  return linear_x + angular_x, linear_y + angular_y
end

-- Returns the effective inverse mass of a body along a contact axis.
local function get_effective_inverse_mass(mass, angular, point_x, point_y, axis_x, axis_y)
  local value = get_inverse_mass(mass)

  if angular ~= nil then
    value = value + AngularImpulse.get_effective_inverse_mass(
      angular.inertia,
      angular.center_x,
      angular.center_y,
      point_x,
      point_y,
      axis_x,
      axis_y
    )
  end

  return value
end

-- Applies a contact impulse to both linear and optional angular body state.
local function apply_body_impulse(velocity, mass, angular, point_x, point_y, impulse_x, impulse_y)
  local inverse_mass = get_inverse_mass(mass)

  if velocity ~= nil and inverse_mass > 0 then velocity:add(impulse_x * inverse_mass, impulse_y * inverse_mass) end

  if angular ~= nil then
    AngularImpulse.apply(
      angular.angular_velocity,
      angular.inertia,
      angular.center_x,
      angular.center_y,
      point_x,
      point_y,
      impulse_x,
      impulse_y
    )
  end
end

-- Returns the relative velocity of two bodies at a contact point.
local function get_relative_contact_velocity(source_velocity, source_angular, target_velocity, target_angular, point_x,
                                             point_y)
  local source_x, source_y = get_contact_velocity(source_velocity, source_angular, point_x, point_y)
  local target_x, target_y = get_contact_velocity(target_velocity, target_angular, point_x, point_y)

  return source_x - target_x, source_y - target_y
end

-- Applies restitution and friction impulses including optional rotational response.
function ContactImpulse.apply_pair(source_velocity, source_mass, target_velocity, target_mass, normal_x, normal_y,
                                   properties, rotational)
  assert(source_velocity ~= nil, "source velocity is required")
  assert(source_mass ~= nil, "source mass is required")
  assert((target_velocity == nil) == (target_mass == nil), "target velocity and mass must both be present or absent")

  properties = properties or {}
  rotational = rotational or {}

  local point_x = rotational.point_x or 0
  local point_y = rotational.point_y or 0
  local source_angular = rotational.source
  local target_angular = rotational.target
  local restitution = properties.restitution or 0
  local static_friction = properties.static_friction or 0
  local dynamic_friction = properties.dynamic_friction or 0
  local normal_length = math.sqrt(normal_x * normal_x + normal_y * normal_y)

  if normal_length <= Geometry.EPSILON then return false end

  normal_x = normal_x / normal_length
  normal_y = normal_y / normal_length

  local relative_x, relative_y = get_relative_contact_velocity(
    source_velocity, source_angular,
    target_velocity, target_angular,
    point_x, point_y
  )

  local normal_velocity = Geometry.dot(relative_x, relative_y, normal_x, normal_y)
  if normal_velocity >= 0 then return false end

  local normal_inverse_mass =
      get_effective_inverse_mass(source_mass, source_angular, point_x, point_y, normal_x, normal_y)
      + get_effective_inverse_mass(target_mass, target_angular, point_x, point_y, normal_x, normal_y)

  if normal_inverse_mass <= Geometry.EPSILON then return false end

  local normal_impulse = -(1 + restitution) * normal_velocity / normal_inverse_mass
  local normal_impulse_x = normal_x * normal_impulse
  local normal_impulse_y = normal_y * normal_impulse

  apply_body_impulse(source_velocity, source_mass, source_angular, point_x, point_y, normal_impulse_x, normal_impulse_y)
  apply_body_impulse(target_velocity, target_mass, target_angular, point_x, point_y, -normal_impulse_x, -
  normal_impulse_y)

  relative_x, relative_y = get_relative_contact_velocity(
    source_velocity, source_angular,
    target_velocity, target_angular,
    point_x, point_y
  )

  local tangent_velocity = Geometry.dot(relative_x, relative_y, normal_x, normal_y)
  local tangent_x = relative_x - tangent_velocity * normal_x
  local tangent_y = relative_y - tangent_velocity * normal_y
  local tangent_length = math.sqrt(tangent_x * tangent_x + tangent_y * tangent_y)
  local tangent_impulse_x = 0
  local tangent_impulse_y = 0

  if tangent_length > Geometry.EPSILON then
    tangent_x = tangent_x / tangent_length
    tangent_y = tangent_y / tangent_length

    local tangent_speed = Geometry.dot(relative_x, relative_y, tangent_x, tangent_y)
    local tangent_inverse_mass =
        get_effective_inverse_mass(source_mass, source_angular, point_x, point_y, tangent_x, tangent_y)
        + get_effective_inverse_mass(target_mass, target_angular, point_x, point_y, tangent_x, tangent_y)

    if tangent_inverse_mass > Geometry.EPSILON then
      local tangent_impulse = -tangent_speed / tangent_inverse_mass
      local static_limit = static_friction * normal_impulse

      if math.abs(tangent_impulse) > static_limit then
        local tangent_sign = tangent_speed < 0 and -1 or 1
        tangent_impulse = -tangent_sign * dynamic_friction * normal_impulse
      end

      tangent_impulse_x = tangent_x * tangent_impulse
      tangent_impulse_y = tangent_y * tangent_impulse

      apply_body_impulse(source_velocity, source_mass, source_angular, point_x, point_y, tangent_impulse_x,
        tangent_impulse_y)
      apply_body_impulse(target_velocity, target_mass, target_angular, point_x, point_y, -tangent_impulse_x,
        -tangent_impulse_y)
    end
  end

  return true, normal_impulse_x + tangent_impulse_x, normal_impulse_y + tangent_impulse_y
end

-- Applies contact impulses between a dynamic body and an immovable surface.
function ContactImpulse.apply(velocity, mass, normal_x, normal_y, properties)
  return ContactImpulse.apply_pair(velocity, mass, nil, nil, normal_x, normal_y, properties)
end

return ContactImpulse
