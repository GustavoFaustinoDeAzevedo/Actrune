local AngularVelocity = {}
AngularVelocity.__index = AngularVelocity

-- Creates an angular velocity state in radians per second.
function AngularVelocity.new(value)
  assert(value == nil or type(value) == "number", "angular velocity must be a number")
  return setmetatable({ value = value or 0 }, AngularVelocity)
end

-- Sets the current angular velocity.
function AngularVelocity:set(value)
  assert(type(value) == "number", "angular velocity must be a number")
  self.value = value
end

-- Adds a change to the current angular velocity.
function AngularVelocity:add(value)
  assert(type(value) == "number", "angular velocity change must be a number")
  self.value = self.value + value
end

-- Returns the current angular velocity.
function AngularVelocity:get()
  return self.value
end

-- Clears the current angular velocity.
function AngularVelocity:clear()
  self.value = 0
end

-- Returns the angular displacement produced over a time interval.
function AngularVelocity:get_displacement(dt)
  return self.value * dt
end

return AngularVelocity
