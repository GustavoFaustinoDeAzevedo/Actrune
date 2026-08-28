local Actrune = require("engine.core.actrune")
local ActruneRuntimeConfiguration = require("engine.core.project.actrune_runtime_configuration")

local ProjectRuntime = {}
ProjectRuntime.__index = ProjectRuntime

-- Creates a runtime that coordinates one loaded project through registered runtime systems.
function ProjectRuntime.new(options)
  options = options or {}

  local self = setmetatable({}, ProjectRuntime)

  self.project = options.project
  self.renderer_factory = options.renderer_factory
  self.system_registry = options.system_registry or ActruneRuntimeConfiguration.create()

  assert(self.project ~= nil, "project runtime requires a loaded project")
  assert(self.system_registry ~= nil, "project runtime requires a system registry")

  self.runtime = Actrune.new()
  self.systems = {}
  self.systems_by_name = {}
  self.renderer = nil

  self:_add_entities()
  self:_bind_input()
  self:_create_systems()
  self:_create_renderer()

  return self
end

-- Adds every loaded project entity to the Actrune runtime world.
function ProjectRuntime:_add_entities()
  for _, entity in ipairs(self.project.entities) do self.runtime:add_entity(entity) end
end

-- Binds the project's default input map when one is available.
function ProjectRuntime:_bind_input()
  local input_maps = self.project.resources["input_map"]
  if input_maps == nil then return end

  local input_map = input_maps:get("default")
  if input_map ~= nil then input_map:bind(self.runtime) end
end

-- Creates and initializes all registered runtime systems.
function ProjectRuntime:_create_systems()
  local context = self:_create_context()

  for _, definition in ipairs(self.system_registry:get_definitions()) do
    local system = definition.factory(context)

    assert(system ~= nil, "runtime system factory returned nil: " .. definition.name)
    assert(self.systems_by_name[definition.name] == nil, "duplicate runtime system: " .. definition.name)

    if type(system.initialize) == "function" then system:initialize(context) end

    table.insert(self.systems, {
      name = definition.name,
      system = system
    })

    self.systems_by_name[definition.name] = system
  end
end

-- Creates the optional project renderer.
function ProjectRuntime:_create_renderer()
  if self.renderer_factory == nil then return end

  self.renderer = self.renderer_factory(self:_create_context())
end

-- Creates the context shared with runtime systems and project adapters.
function ProjectRuntime:_create_context()
  return {
    project = self.project,
    runtime = self.runtime,
    project_runtime = self
  }
end

-- Returns a registered runtime system by name.
function ProjectRuntime:get_system(name)
  return self.systems_by_name[name]
end

-- Returns the provider that registered one runtime system.
function ProjectRuntime:get_system_provider(name)
  return self.system_registry:get_provider(name)
end

-- Advances all registered runtime systems and the underlying Actrune runtime.
function ProjectRuntime:update(dt)
  local context = self:_create_context()

  for _, entry in ipairs(self.systems) do
    local system = entry.system
    if type(system.update) == "function" then system:update(dt, context) end
  end

  self.runtime:update(dt)
end

-- Draws registered runtime systems and the optional project renderer.
function ProjectRuntime:draw()
  local context = self:_create_context()

  for _, entry in ipairs(self.systems) do
    local system = entry.system
    if type(system.draw) == "function" then system:draw(context) end
  end

  if self.renderer ~= nil then self.renderer:draw() end
end

-- Forwards one keyboard press to the Actrune runtime.
function ProjectRuntime:key_pressed(key)
  self.runtime:key_pressed(key)
end

-- Forwards one keyboard release to the Actrune runtime.
function ProjectRuntime:key_released(key)
  self.runtime:key_released(key)
end

-- Returns the underlying Actrune runtime.
function ProjectRuntime:get_runtime()
  return self.runtime
end

-- Returns the loaded project.
function ProjectRuntime:get_project()
  return self.project
end

return ProjectRuntime
