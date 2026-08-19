local Acceleration = {}
Acceleration.__index = Acceleration

-- Creates an acceleration state with optional initial components.
function Acceleration.new(options)
  options = options or {}

  local self = setmetatable({}, Acceleration)

  self.x = options.x or 0
  self.y = options.y or 0

  return self
end

-- Sets both acceleration components.
function Acceleration:set(x, y)
  self.x = x
  self.y = y
end

-- Adds values to the current acceleration components.
function Acceleration:add(x, y)
  self.x = self.x + x
  self.y = self.y + y
end

-- Returns the current acceleration components.
function Acceleration:get()
  return self.x, self.y
end

-- Calculates the velocity change produced over elapsed time.
function Acceleration:get_velocity_change(dt)
  return self.x * dt,
      self.y * dt
end

-- Clears both acceleration components.
function Acceleration:clear()
  self.x = 0
  self.y = 0
end

return Acceleration
