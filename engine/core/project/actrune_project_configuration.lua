local ProjectConfiguration = require("engine.core.project.project_configuration")
local ActruneTypeCatalog = require("engine.core.project.actrune_type_catalog")
local ActruneRuntimeConfiguration = require("engine.core.project.actrune_runtime_configuration")
local ActruneResourceTypes = require("engine.core.resources.actrune_resource_types")
local TransitionResourceTypes = require("engine.core.resources.transition_resource_types")

local ActruneProjectConfiguration = {}

-- Creates the default project configuration provided by Actrune.
function ActruneProjectConfiguration.create()
  local configuration = ProjectConfiguration.new({
    type_catalog = ActruneTypeCatalog.create(),
    runtime_system_registry = ActruneRuntimeConfiguration.create()
  })

  local actrune = configuration:create_register("actrune")
  ActruneResourceTypes.register(actrune)
  TransitionResourceTypes.register(actrune, configuration:get_type_catalog())

  return configuration
end

return ActruneProjectConfiguration
