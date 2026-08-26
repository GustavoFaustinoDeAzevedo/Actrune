local GridContext = {}
GridContext.__index = GridContext

-- Creates an entity grid context backed by the currently active grid metrics.
function GridContext.new(options)
  options = options or {}

  local self = setmetatable({}, GridContext)
  self.metrics = options.metrics

  assert(self.metrics ~= nil, "grid context requires grid metrics")

  return self
end

-- Changes the grid metrics currently active for this context.
function GridContext:set_metrics(metrics)
  assert(metrics ~= nil, "grid context metrics are required")
  self.metrics = metrics
end

-- Returns the grid metrics currently active for this context.
function GridContext:get_metrics()
  return self.metrics
end

-- Returns a property from the currently active grid metrics.
function GridContext:get(name, fallback)
  assert(self.metrics ~= nil, "grid context does not have active grid metrics")
  return self.metrics:get(name, fallback)
end

return GridContext
