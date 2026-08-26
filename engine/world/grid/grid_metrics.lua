local GridMetrics = {}
GridMetrics.__index = GridMetrics

-- Creates a grid metrics resource containing spatial grid properties.
function GridMetrics.new(options)
  options = options or {}

  local self = setmetatable({}, GridMetrics)

  self.properties = {
    cell_size = options.cell_size
  }

  assert(type(self.properties.cell_size) == "number", "grid cell size must be a number")
  assert(self.properties.cell_size > 0, "grid cell size must be greater than zero")

  return self
end

-- Returns a named grid property or a fallback when it is not defined.
function GridMetrics:get(name, fallback)
  local value = self.properties[name]
  if value == nil then return fallback end
  return value
end

return GridMetrics
