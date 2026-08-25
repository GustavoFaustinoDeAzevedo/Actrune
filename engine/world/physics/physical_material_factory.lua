local PhysicalMaterial = require("engine.world.physics.physical_material")

local PhysicalMaterialFactory = {}

-- Creates a runtime physical material from a serializable definition.
function PhysicalMaterialFactory.create(definition)
  assert(type(definition) == "table", "physical material definition must be a table")

  local properties = {}

  for name, value in pairs(definition.properties or {}) do properties[name] = value end

  return PhysicalMaterial.new(properties)
end

return PhysicalMaterialFactory
