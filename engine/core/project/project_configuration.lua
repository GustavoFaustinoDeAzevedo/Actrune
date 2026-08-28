local ProjectConfigurationRegister = require("engine.core.project.project_configuration_register")

local ProjectConfiguration = {}
ProjectConfiguration.__index = ProjectConfiguration

-- Creates a project configuration containing its extensible types and runtime systems.
function ProjectConfiguration.new(options)
  options = options or {}

  local self = setmetatable({}, ProjectConfiguration)
  self.type_catalog = options.type_catalog
  self.runtime_system_registry = options.runtime_system_registry

  assert(self.type_catalog ~= nil, "project configuration requires a type catalog")
  assert(self.runtime_system_registry ~= nil, "project configuration requires a runtime system registry")

  return self
end

-- Returns the type catalog used by this project configuration.
function ProjectConfiguration:get_type_catalog()
  return self.type_catalog
end

-- Returns the runtime system registry used by this project configuration.
function ProjectConfiguration:get_runtime_system_registry()
  return self.runtime_system_registry
end

-- Creates a provider-scoped register that can contribute types and runtime systems.
function ProjectConfiguration:create_register(provider)
  return ProjectConfigurationRegister.new(self, provider)
end

return ProjectConfiguration
