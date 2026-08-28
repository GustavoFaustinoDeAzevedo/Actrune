local ProjectLoader = require("engine.core.project.project_loader")
local ActruneProjectConfiguration = require("engine.core.project.actrune_project_configuration")

local ActruneProjectLoader = {}
ActruneProjectLoader.__index = ActruneProjectLoader

-- Creates a project loader configured with isolated built-in Actrune capabilities.
function ActruneProjectLoader.new(options)
  options = options or {}

  local self = setmetatable({}, ActruneProjectLoader)

  self.configuration = options.configuration or ActruneProjectConfiguration.create()

  self.loader = ProjectLoader.new({
    configuration = self.configuration
  })

  return self
end

-- Registers a named event action available to project event definitions.
function ActruneProjectLoader:register_event_action(name, callback)
  self.loader:register_event_action(name, callback)
end

-- Creates a provider-scoped register for extending project capabilities.
function ActruneProjectLoader:create_register(provider)
  return self.configuration:create_register(provider)
end

-- Returns the complete configuration used to load and execute this project.
function ActruneProjectLoader:get_configuration()
  return self.configuration
end

-- Returns the isolated extensible type catalog used by this loader.
function ActruneProjectLoader:get_type_catalog()
  return self.configuration:get_type_catalog()
end

-- Loads and validates one Actrune project definition.
function ActruneProjectLoader:load(definition)
  return self.loader:load(definition)
end

-- Returns the underlying generic project loader for advanced configuration.
function ActruneProjectLoader:get_loader()
  return self.loader
end

return ActruneProjectLoader
