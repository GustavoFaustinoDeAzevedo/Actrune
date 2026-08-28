local RuntimeSystemRegistry = require("engine.core.project.runtime_system_registry")

local GridContextRuntimeSystem = require("engine.world.grid.grid_context_runtime_system")
local ControlRuntimeSystem = require("engine.world.control.control_runtime_system")
local PhysicsRuntimeSystem = require("engine.world.physics.physics_runtime_system")

local ActruneRuntimeConfiguration = {}

-- Creates the default ordered runtime system registry provided by Actrune.
function ActruneRuntimeConfiguration.create()
  local systems = RuntimeSystemRegistry.new()

  local actrune = systems:create_register({
    provider = "actrune"
  })

  actrune:register("grid_context", function()
    return GridContextRuntimeSystem.new()
  end, 100)

  actrune:register("controls", function()
    return ControlRuntimeSystem.new()
  end, 200)

  actrune:register("physics", function()
    return PhysicsRuntimeSystem.new({
      gravity_x = 0,
      gravity_y = 980,
      sleep = true,
      step = 1 / 60,
      stall_threshold = 0.1,
      max_steps = 8
    })
  end, 300)

  return systems
end

return ActruneRuntimeConfiguration
