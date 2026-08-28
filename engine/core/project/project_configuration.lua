local FactoryRegistry = require("engine.core.definitions.factory_registry")
local ProjectConfigurationRegister = require("engine.core.project.project_configuration_register")

local ProjectConfiguration = {}
ProjectConfiguration.__index = ProjectConfiguration

-- Creates a project configuration containing its extensible types, resources, and runtime systems.
function ProjectConfiguration.new(options)
  options = options or {}

  local self = setmetatable({}, ProjectConfiguration)

  self.type_catalog = options.type_catalog
  self.runtime_system_registry = options.runtime_system_registry
  self.resource_types = options.resource_types or FactoryRegistry.new({ kind = "resource type" })

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

-- Registers one serializable resource type and its provider metadata.
function ProjectConfiguration:register_resource_type(type_name, factory, definition, options)
  self.resource_types:register(type_name, factory, definition, options)
end

-- Returns whether a serializable resource type is registered.
function ProjectConfiguration:has_resource_type(type_name)
  return self.resource_types:has(type_name)
end

-- Creates one runtime resource from a registered resource type.
function ProjectConfiguration:create_resource(type_name, definition, context)
  return self.resource_types:create(type_name, definition, context)
end

-- Returns metadata associated with one serializable resource type.
function ProjectConfiguration:get_resource_definition(type_name)
  return self.resource_types:get_definition(type_name)
end

-- Returns the provider associated with one serializable resource type.
function ProjectConfiguration:get_resource_provider(type_name)
  return self.resource_types:get_provider(type_name)
end

-- Returns all registered resource type names in deterministic order.
function ProjectConfiguration:get_resource_type_names()
  return self.resource_types:get_type_names()
end

-- Creates a provider-scoped register that can contribute project capabilities.
function ProjectConfiguration:create_register(provider)
  return ProjectConfigurationRegister.new(self, provider)
end

return ProjectConfiguration
