local ProjectConfigurationRegister = {}
ProjectConfigurationRegister.__index = ProjectConfigurationRegister

-- Creates a project configuration register associated with one provider.
function ProjectConfigurationRegister.new(configuration, provider)
  local self = setmetatable({}, ProjectConfigurationRegister)

  self.configuration = configuration
  self.provider = provider

  assert(self.configuration ~= nil, "project configuration register requires a configuration")
  assert(type(self.provider) == "string", "project configuration register provider must be a string")
  assert(self.provider ~= "", "project configuration register provider must not be empty")

  self.type_register = self.configuration:get_type_catalog():create_register({ provider = provider })
  self.runtime_system_register = self.configuration:get_runtime_system_registry():create_register({ provider = provider })

  return self
end

-- Returns the provider associated with this project configuration register.
function ProjectConfigurationRegister:get_provider()
  return self.provider
end

-- Ensures that one extensible type family exists.
function ProjectConfigurationRegister:ensure_type_registry(kind, options)
  return self.type_register:ensure_registry(kind, options)
end

-- Registers one serializable type under this register's provider.
function ProjectConfigurationRegister:register_type(kind, type_name, factory, definition)
  self.type_register:register(kind, type_name, factory, definition)
end

-- Registers one serializable resource type under this register's provider.
function ProjectConfigurationRegister:register_resource_type(type_name, factory, definition)
  self.configuration:register_resource_type(type_name, factory, definition, {
    provider = self.provider
  })
end

-- Registers one runtime system under this register's provider.
function ProjectConfigurationRegister:register_runtime_system(name, factory, order)
  self.runtime_system_register:register(name, factory, order)
end

-- Returns the underlying provider-scoped type register.
function ProjectConfigurationRegister:get_type_register()
  return self.type_register
end

-- Returns the underlying provider-scoped runtime system register.
function ProjectConfigurationRegister:get_runtime_system_register()
  return self.runtime_system_register
end

return ProjectConfigurationRegister
