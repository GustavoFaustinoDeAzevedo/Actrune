local AngularImpulse = {}

-- Calculates the two-dimensional scalar cross product.
local function cross(a_x, a_y, b_x, b_y)
  return a_x * b_y - a_y * b_x
end

-- Returns the linear velocity produced by angular velocity at a world-space point.
function AngularImpulse.get_point_velocity(angular_velocity, center_x, center_y, point_x, point_y)
  if angular_velocity == nil then return 0, 0 end

  local arm_x = point_x - center_x
  local arm_y = point_y - center_y
  local omega = angular_velocity:get()

  return -omega * arm_y, omega * arm_x
end

-- Returns the rotational contribution to inverse effective mass along an axis.
function AngularImpulse.get_effective_inverse_mass(inertia, center_x, center_y, point_x, point_y, axis_x, axis_y)
  if inertia == nil then return 0 end

  local arm_x = point_x - center_x
  local arm_y = point_y - center_y
  local arm_cross_axis = cross(arm_x, arm_y, axis_x, axis_y)

  return arm_cross_axis * arm_cross_axis * inertia:get_inverse()
end

-- Applies an impulse at a world-space point to angular velocity.
function AngularImpulse.apply(angular_velocity, inertia, center_x, center_y, point_x, point_y, impulse_x, impulse_y)
  if angular_velocity == nil or inertia == nil then return false end

  local arm_x = point_x - center_x
  local arm_y = point_y - center_y
  local angular_change = cross(arm_x, arm_y, impulse_x, impulse_y) * inertia:get_inverse()

  angular_velocity:add(angular_change)
  return true
end

return AngularImpulse
