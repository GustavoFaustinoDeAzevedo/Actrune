local FixedStep = {}
FixedStep.__index = FixedStep

-- Creates a fixed simulation step with configurable stall handling.
function FixedStep.new(options)
  options = options or {}

  local self = setmetatable({}, FixedStep)
  self.step = options.step or (1 / 60)
  self.stall_threshold = options.stall_threshold or 0.1
  self.max_steps = options.max_steps or 8
  self.accumulator = 0
  self.last_steps = 0

  return self
end

-- Advances the simulation using fixed steps while discarding abnormally long frame stalls.
function FixedStep:update(dt, callback)
  assert(type(callback) == "function", "fixed-step callback is required")

  self.last_steps = 0

  if dt >= self.stall_threshold then
    self.accumulator = 0
    return
  end

  self.accumulator = self.accumulator + dt

  while self.accumulator >= self.step and self.last_steps < self.max_steps do
    callback(self.step)
    self.accumulator = self.accumulator - self.step
    self.last_steps = self.last_steps + 1
  end

  if self.last_steps >= self.max_steps then self.accumulator = 0 end
end

-- Clears any accumulated simulation time.
function FixedStep:reset()
  self.accumulator = 0
end

-- Returns the interpolation fraction between the previous and next simulation states.
function FixedStep:get_alpha()
  return self.accumulator / self.step
end

return FixedStep
