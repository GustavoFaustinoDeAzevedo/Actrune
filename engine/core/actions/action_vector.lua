local ActionVector = {}
ActionVector.__index = ActionVector

-- Creates a two-dimensional action vector from optional horizontal and vertical axes.
function ActionVector.new(options)
  options = options or {}

  local self = setmetatable({}, ActionVector)

  self.x_axis = options.x_axis
  self.y_axis = options.y_axis

  return self
end

-- Resolves the configured axes into a two-dimensional input vector.
function ActionVector:resolve(runtime)
  local x = 0
  local y = 0

  if self.x_axis ~= nil then
    x = self.x_axis:resolve(runtime)
  end

  if self.y_axis ~= nil then
    y = self.y_axis:resolve(runtime)
  end

  return x, y
end

return ActionVector
