local GridArea = {}
GridArea.__index = GridArea

-- Creates an area that optionally supplies grid metrics to entities inside it.
function GridArea.new(options)
  options = options or {}

  local self = setmetatable({}, GridArea)

  self.shape = options.shape
  self.metrics = options.metrics
  self.priority = options.priority or 0

  assert(type(self.shape) == "string", "grid area shape must be a shape name")
  assert(type(self.priority) == "number", "grid area priority must be a number")

  return self
end

-- Returns the entity shape defining this grid area.
function GridArea:get_shape()
  return self.shape
end

-- Returns the grid metrics supplied by this area or nil when the area disables grid context.
function GridArea:get_metrics()
  return self.metrics
end

-- Returns whether this area supplies grid metrics.
function GridArea:has_metrics()
  return self.metrics ~= nil
end

-- Returns the priority used when multiple grid areas overlap.
function GridArea:get_priority()
  return self.priority
end

return GridArea
