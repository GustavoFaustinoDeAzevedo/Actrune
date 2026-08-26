local GridContext = {}
GridContext.__index = GridContext

-- Creates an entity grid context with optional default grid metrics.
function GridContext.new(options)
  options = options or {}

  local self = setmetatable({}, GridContext)

  self.default_metrics = options.metrics
  self.metrics = options.metrics

  return self
end

-- Changes the grid metrics currently active for this context.
function GridContext:set_metrics(metrics)
  self.metrics = metrics
end

-- Restores the grid context to its default metrics.
function GridContext:reset_metrics()
  self.metrics = self.default_metrics
end

-- Returns whether this context currently has active grid metrics.
function GridContext:has_metrics()
  return self.metrics ~= nil
end

-- Returns the grid metrics currently active for this context.
function GridContext:get_metrics()
  return self.metrics
end

-- Returns a property from the active grid metrics or a fallback when no grid is active.
function GridContext:get(name, fallback)
  if self.metrics == nil then return fallback end
  return self.metrics:get(name, fallback)
end

return GridContext
