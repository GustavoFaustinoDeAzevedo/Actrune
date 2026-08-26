local GridMetrics = require("engine.world.grid.grid_metrics")

local GridMetricsFactory = {}

-- Creates runtime grid metrics from a serializable definition.
function GridMetricsFactory.create(definition)
  assert(type(definition) == "table", "grid metrics definition must be a table")

  return GridMetrics.new({
    cell_width = definition.cell_width,
    cell_height = definition.cell_height
  })
end

return GridMetricsFactory
