local ControlSystem = require("engine.world.control.control_system")

local ControlRuntimeSystem = {}
ControlRuntimeSystem.__index = ControlRuntimeSystem

-- Creates the runtime adapter for control-driven project components.
function ControlRuntimeSystem.new()
  return setmetatable({
    system = nil
  }, ControlRuntimeSystem)
end

-- Initializes control-driven components against the current spatial world.
function ControlRuntimeSystem:initialize(context)
  self.system = ControlSystem.new(context.runtime.world)
  self.system:add_project(context.project)
end

-- Updates every control-driven project component.
function ControlRuntimeSystem:update(dt, context)
  self.system:update(context.runtime, dt)
end

return ControlRuntimeSystem
