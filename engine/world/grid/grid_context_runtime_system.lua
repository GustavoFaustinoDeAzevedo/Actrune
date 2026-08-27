local GridContextSystem = require("engine.world.grid.grid_context_system")

local GridContextRuntimeSystem = {}
GridContextRuntimeSystem.__index = GridContextRuntimeSystem

-- Creates the runtime adapter for contextual grid resolution.
function GridContextRuntimeSystem.new()
  return setmetatable({
    system = nil
  }, GridContextRuntimeSystem)
end

-- Initializes contextual grid resolution for the loaded project.
function GridContextRuntimeSystem:initialize(context)
  self.system = GridContextSystem.new()
  self.system:add_project(context.project)
  self.system:update()
end

-- Updates entity grid contexts from their current spatial areas.
function GridContextRuntimeSystem:update(dt, context)
  self.system:update()
end

return GridContextRuntimeSystem
