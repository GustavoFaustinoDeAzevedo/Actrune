local Actrune = require("engine.core.actrune")
local FixedStep = require("engine.core.time.fixed_step")

local GridContextSystem = require("engine.world.grid.grid_context_system")
local ControlSystem = require("engine.world.control.control_system")
local Box2DBackend = require("engine.world.physics.backends.box2d_backend")

local ProjectRuntime = {}
ProjectRuntime.__index = ProjectRuntime

-- Creates a runtime that coordinates one loaded Actrune project and its systems.
function ProjectRuntime.new(options)
  options = options or {}

  local self = setmetatable({}, ProjectRuntime)

  self.project = options.project
  self.renderer_factory = options.renderer_factory

  assert(self.project ~= nil, "project runtime requires a loaded project")

  self.runtime = Actrune.new()

  self.grid_context_system = nil
  self.control_system = nil
  self.physics_backend = nil
  self.physics_step = nil
  self.renderer = nil

  self:_add_entities()
  self:_bind_input()
  self:_create_grid_contexts()
  self:_create_controls()
  self:_create_physics()
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

-- Creates the system that resolves contextual grid areas.
function ProjectRuntime:_create_grid_contexts()
  self.grid_context_system = GridContextSystem.new()
  self.grid_context_system:add_project(self.project)
  self.grid_context_system:update()
end

-- Creates the system that updates control-driven components.
function ProjectRuntime:_create_controls()
  self.control_system = ControlSystem.new(self.runtime.world)
  self.control_system:add_project(self.project)
end

-- Creates the physics backend and registers all rigid body entities.
function ProjectRuntime:_create_physics()
  self.physics_backend = Box2DBackend.new({
    gravity_x = 0,
    gravity_y = 980,
    sleep = true
  })

  for _, entity in ipairs(self.project.entities) do
    if entity:get_component("rigid_body") ~= nil then self.physics_backend:add_entity(entity) end
  end

  self.physics_step = FixedStep.new({
    step = 1 / 60,
    stall_threshold = 0.1,
    max_steps = 8
  })
end

-- Creates the optional project renderer.
function ProjectRuntime:_create_renderer()
  if self.renderer_factory == nil then return end

  self.renderer = self.renderer_factory({
    project = self.project,
    runtime = self.runtime,
    box2d = self.physics_backend,
    physics_step = self.physics_step
  })
end

-- Advances one fixed physics simulation step.
function ProjectRuntime:_update_physics(step_dt)
  self.physics_backend:update(step_dt)
end

-- Advances all project systems in their configured execution order.
function ProjectRuntime:update(dt)
  self.grid_context_system:update()
  self.control_system:update(self.runtime, dt)
  self.physics_step:update(dt, function(step_dt) self:_update_physics(step_dt) end)
  self.runtime:update(dt)
end

-- Draws the project through its configured renderer.
function ProjectRuntime:draw()
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

-- Returns the configured physics backend.
function ProjectRuntime:get_physics_backend()
  return self.physics_backend
end

-- Returns the loaded project.
function ProjectRuntime:get_project()
  return self.project
end

return ProjectRuntime
