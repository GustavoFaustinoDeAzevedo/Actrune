local GridContext = {}
GridContext.__index = GridContext

-- Creates an entity grid context with default grid metrics.
function GridContext.new(options)
  options = options or {}

  local self = setmetatable({}, GridContext)

  self.default_metrics = options.metrics
  self.metrics = options.metrics

  assert(self.default_metrics ~= nil, "grid context requires default grid metrics")

  return self
end

-- Changes the grid metrics currently active for this context.
function GridContext:set_metrics(metrics)
  assert(metrics ~= nil, "grid context metrics are required")
  self.metrics = metrics
end

-- Restores the grid context to its default metrics.
function GridContext:reset_metrics()
  self.metrics = self.default_metrics
end

-- Returns the grid metrics currently active for this context.
function GridContext:get_metrics()
  return self.metrics
end

-- Returns a property from the currently active grid metrics.
function GridContext:get(name, fallback)
  local value = self.metrics:get(name, fallback)
  return value
end

return GridContext
