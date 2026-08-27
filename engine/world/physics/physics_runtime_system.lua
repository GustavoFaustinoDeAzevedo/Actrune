local FixedStep = require("engine.core.time.fixed_step")
local Box2DBackend = require("engine.world.physics.backends.box2d_backend")

local PhysicsRuntimeSystem = {}
PhysicsRuntimeSystem.__index = PhysicsRuntimeSystem

-- Creates the default Actrune rigid body physics runtime system.
function PhysicsRuntimeSystem.new(options)
  options = options or {}

  return setmetatable({
    gravity_x = options.gravity_x or 0,
    gravity_y = options.gravity_y or 980,
    sleep = options.sleep ~= false,
    step = options.step or (1 / 60),
    stall_threshold = options.stall_threshold or 0.1,
    max_steps = options.max_steps or 8,
    backend = nil,
    fixed_step = nil
  }, PhysicsRuntimeSystem)
end

-- Initializes the physics backend and registers all project rigid bodies.
function PhysicsRuntimeSystem:initialize(context)
  self.backend = Box2DBackend.new({
    gravity_x = self.gravity_x,
    gravity_y = self.gravity_y,
    sleep = self.sleep
  })

  for _, entity in ipairs(context.project.entities) do
    if entity:get_component("rigid_body") ~= nil then self.backend:add_entity(entity) end
  end

  self.fixed_step = FixedStep.new({
    step = self.step,
    stall_threshold = self.stall_threshold,
    max_steps = self.max_steps
  })
end

-- Advances rigid body physics through fixed simulation steps.
function PhysicsRuntimeSystem:update(dt, context)
  self.fixed_step:update(dt, function(step_dt)
    self.backend:update(step_dt)
  end)
end

-- Returns the active physics backend.
function PhysicsRuntimeSystem:get_backend()
  return self.backend
end

-- Returns the active fixed-step scheduler.
function PhysicsRuntimeSystem:get_fixed_step()
  return self.fixed_step
end

return PhysicsRuntimeSystem
