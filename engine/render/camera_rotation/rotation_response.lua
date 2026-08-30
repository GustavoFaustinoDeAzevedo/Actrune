local RotationResponse = {}
RotationResponse.__index = RotationResponse

-- Resolves the shortest signed angular difference between two rotations.
local function shortest_angle_delta(current, target)
  return (target - current + math.pi) % (math.pi * 2) - math.pi
end

-- Creates an angular response controlled by the time required to halve the remaining rotation.
function RotationResponse.new(options)
  options = options or {}

  local self = setmetatable({}, RotationResponse)
  self.half_life = options.half_life or 0

  assert(type(self.half_life) == "number" and self.half_life >= 0, "rotation response half_life must be zero or greater")

  return self
end

-- Changes the angular response half-life.
function RotationResponse:set_half_life(half_life)
  assert(type(half_life) == "number" and half_life >= 0, "rotation response half_life must be zero or greater")
  self.half_life = half_life
end

-- Resolves the next rotation through the shortest angular path.
function RotationResponse:resolve(current, target, dt)
  if self.half_life == 0 then return target end
  if dt <= 0 then return current end

  local delta = shortest_angle_delta(current, target)
  local response = 1 - 0.5 ^ (dt / self.half_life)

  return current + delta * response
end

return RotationResponse
