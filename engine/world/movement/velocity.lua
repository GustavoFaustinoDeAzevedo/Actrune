local Velocity = {}
Velocity.__index = Velocity

-- Creates a velocity state with optional initial components.
function Velocity.new(options)
  options = options or {}

  local self = setmetatable({}, Velocity)

  self.x = options.x or 0
  self.y = options.y or 0

  return self
end

-- Sets both velocity components.
function Velocity:set(x, y)
  self.x = x
  self.y = y
end

-- Adds values to the current velocity components.
function Velocity:add(x, y)
  self.x = self.x + x
  self.y = self.y + y
end

-- Returns the current velocity components.
function Velocity:get()
  return self.x, self.y
end

-- Returns the magnitude of the current velocity.
function Velocity:get_speed()
  return math.sqrt(
    self.x * self.x
    + self.y * self.y
  )
end

-- Clears both velocity components.
function Velocity:clear()
  self.x = 0
  self.y = 0
end

-- Calculates the displacement produced by the current velocity over elapsed time.
function Velocity:get_displacement(dt)
  return self.x * dt, self.y * dt
end

return Velocity
