local InputMap = require("engine.core.input.input_map")

local InputMapFactory = {}

-- Creates a runtime input map from a serializable definition.
function InputMapFactory.create(definition)
  assert(type(definition) == "table", "input map definition must be a table")

  return InputMap.new({
    keys = definition.keys,
    spatial_actions = definition.spatial_actions
  })
end

return InputMapFactory
