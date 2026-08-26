local GridMetrics = {}
GridMetrics.__index = GridMetrics

-- Creates grid metrics containing independent horizontal and vertical cell dimensions.
function GridMetrics.new(options)
  options = options or {}

  local self = setmetatable({}, GridMetrics)

  self.properties = {
    cell_width = options.cell_width,
    cell_height = options.cell_height
  }

  assert(type(self.properties.cell_width) == "number", "grid cell width must be a number")
  assert(self.properties.cell_width > 0, "grid cell width must be greater than zero")
  assert(type(self.properties.cell_height) == "number", "grid cell height must be a number")
  assert(self.properties.cell_height > 0, "grid cell height must be greater than zero")

  return self
end

-- Returns a named grid property or a fallback when it is not defined.
function GridMetrics:get(name, fallback)
  local value = self.properties[name]
  if value == nil then return fallback end
  return value
end

return GridMetrics
