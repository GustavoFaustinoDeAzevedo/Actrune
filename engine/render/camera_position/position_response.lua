local PositionResponse = {}
PositionResponse.__index = PositionResponse

-- Creates a position response with shared or independently configurable axis half-lives.
function PositionResponse.new(options)
  options = options or {}

  local self = setmetatable({}, PositionResponse)

  self.half_life = options.half_life or 0
  self.half_life_x = options.half_life_x
  self.half_life_y = options.half_life_y

  assert(type(self.half_life) == "number" and self.half_life >= 0, "position response half_life must be zero or greater")
  assert(self.half_life_x == nil or type(self.half_life_x) == "number" and self.half_life_x >= 0,
    "position response half_life_x must be nil or zero or greater")
  assert(self.half_life_y == nil or type(self.half_life_y) == "number" and self.half_life_y >= 0,
    "position response half_life_y must be nil or zero or greater")

  return self
end

-- Resolves one axis toward its target using a frame-rate-independent half-life.
local function resolve_axis(current, target, dt, half_life)
  if half_life == 0 then return target end
  if dt <= 0 then return current end

  local response = 1 - 0.5 ^ (dt / half_life)
  return current + (target - current) * response
end

-- Changes the shared half-life used by axes without explicit overrides.
function PositionResponse:set_half_life(half_life)
  assert(type(half_life) == "number" and half_life >= 0, "position response half_life must be zero or greater")
  self.half_life = half_life
end

-- Changes the horizontal half-life override, or clears it to use the shared value.
function PositionResponse:set_half_life_x(half_life)
  assert(half_life == nil or type(half_life) == "number" and half_life >= 0,
    "position response half_life_x must be nil or zero or greater")
  self.half_life_x = half_life
end

-- Changes the vertical half-life override, or clears it to use the shared value.
function PositionResponse:set_half_life_y(half_life)
  assert(half_life == nil or type(half_life) == "number" and half_life >= 0,
    "position response half_life_y must be nil or zero or greater")
  self.half_life_y = half_life
end

-- Resolves the next position using independently configurable horizontal and vertical responses.
function PositionResponse:resolve(current_x, current_y, target_x, target_y, dt)
  local half_life_x = self.half_life_x or self.half_life
  local half_life_y = self.half_life_y or self.half_life

  return resolve_axis(current_x, target_x, dt, half_life_x),
      resolve_axis(current_y, target_y, dt, half_life_y)
end

return PositionResponse
