local ProjectConfiguration = require("engine.core.project.project_configuration")
local ActruneTypeCatalog = require("engine.core.project.actrune_type_catalog")
local ActruneRuntimeConfiguration = require("engine.core.project.actrune_runtime_configuration")

local ActruneProjectConfiguration = {}

-- Creates the default project configuration provided by Actrune.
function ActruneProjectConfiguration.create()
  return ProjectConfiguration.new({
    type_catalog = ActruneTypeCatalog.create(),
    runtime_system_registry = ActruneRuntimeConfiguration.create()
  })
end

return ActruneProjectConfiguration
