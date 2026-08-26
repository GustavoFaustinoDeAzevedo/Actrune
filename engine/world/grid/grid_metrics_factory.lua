local GridMetrics = require("engine.world.grid.grid_metrics")

local GridMetricsFactory = {}

-- Creates runtime grid metrics from a serializable definition.
function GridMetricsFactory.create(definition)
  assert(type(definition) == "table", "grid metrics definition must be a table")

  return GridMetrics.new({
    cell_size = definition.cell_size
  })
end

return GridMetricsFactory
