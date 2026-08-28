local PositionResponse = {}
PositionResponse.__index = PositionResponse

-- Creates a position response controlled by the time required to halve the remaining distance.
function PositionResponse.new(options)
  options = options or {}

  local self = setmetatable({}, PositionResponse)
  self.half_life = options.half_life or 0

  assert(type(self.half_life) == "number" and self.half_life >= 0, "position response half_life must be zero or greater")

  return self
end

-- Resolves the next position when approaching a target during one update.
function PositionResponse:resolve(current_x, current_y, target_x, target_y, dt)
  if self.half_life == 0 then return target_x, target_y end
  if dt <= 0 then return current_x, current_y end

  local response = 1 - 0.5 ^ (dt / self.half_life)

  return current_x + (target_x - current_x) * response,
      current_y + (target_y - current_y) * response
end

return PositionResponse
