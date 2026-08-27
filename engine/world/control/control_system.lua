local ComponentUpdateSystem = require("engine.world.systems.component_update_system")

local ControlSystem = {}
ControlSystem.__index = ControlSystem

-- Creates a component update system configured for control-driven capabilities.
function ControlSystem.new(world)
  assert(world ~= nil, "control system requires a world")

  return ComponentUpdateSystem.new({
    bind_method = "bind_control",
    update_method = "update_control",
    order_field = "control_order",
    bind_context = world
  })
end

return ControlSystem
