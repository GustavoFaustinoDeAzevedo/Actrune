local ProjectLoader = require("engine.core.project.project_loader")
local ActruneProjectConfiguration = require("engine.core.project.actrune_project_configuration")

local InputMapFactory = require("engine.core.input.input_map_factory")
local GridMetricsFactory = require("engine.world.grid.grid_metrics_factory")
local ControlProfileFactory = require("engine.world.control.control_profile_factory")
local PhysicalMaterialFactory = require("engine.world.physics.physical_material_factory")

local ActruneProjectLoader = {}
ActruneProjectLoader.__index = ActruneProjectLoader

-- Creates a project loader configured with isolated built-in Actrune capabilities and resources.
function ActruneProjectLoader.new(options)
  options = options or {}

  local self = setmetatable({}, ActruneProjectLoader)

  self.configuration = options.configuration or ActruneProjectConfiguration.create()
  self.type_catalog = self.configuration:get_type_catalog()

  self.loader = ProjectLoader.new({
    type_catalog = self.type_catalog
  })

  self:_register_builtin_resources()

  return self
end

-- Registers all resource types provided by the Actrune engine.
function ActruneProjectLoader:_register_builtin_resources()
  self.loader:register_resource_type(
    "physical_material",
    PhysicalMaterialFactory.create,
    {
      fields = {
        {
          name = "properties",
          type = "property_map",
          allow_custom = true,

          suggestions = {
            { name = "density",     type = "number", min = 0 },
            { name = "restitution", type = "number", min = 0 },
            { name = "friction",    type = "number", min = 0 }
          }
        }
      }
    }
  )

  self.loader:register_resource_type(
    "grid_metrics",
    GridMetricsFactory.create,
    {
      fields = {
        { name = "cell_width",  type = "number", required = true, min_exclusive = 0 },
        { name = "cell_height", type = "number", required = true, min_exclusive = 0 }
      }
    }
  )

  self.loader:register_resource_type("input_map", InputMapFactory.create)
  self.loader:register_resource_type("control_profile", ControlProfileFactory.create)
end

-- Registers a named event action available to project event definitions.
function ActruneProjectLoader:register_event_action(name, callback)
  self.loader:register_event_action(name, callback)
end

-- Returns the isolated extensible type catalog used by this loader.
function ActruneProjectLoader:get_type_catalog()
  return self.type_catalog
end

-- Creates a provider-scoped register for extending project types and runtime systems.
function ActruneProjectLoader:create_register(provider)
  return self.configuration:create_register(provider)
end

-- Returns the complete configuration used to load and execute this project.
function ActruneProjectLoader:get_configuration()
  return self.configuration
end

-- Loads one Actrune project definition and associates its execution configuration.
function ActruneProjectLoader:load(definition)
  local project = self.loader:load(definition)
  project.configuration = self.configuration
  return project
end

-- Returns the underlying generic project loader for advanced configuration.
function ActruneProjectLoader:get_loader()
  return self.loader
end

return ActruneProjectLoader
