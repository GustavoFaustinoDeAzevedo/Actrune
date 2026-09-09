local AnimatedEntityVisualRuntimeSystem = require("engine.render.animated_entity_visual_runtime_system")
local StaticEntityVisualRuntimeSystem = require("engine.render.static_entity_visual_runtime_system")

local RuntimeConfiguration = {}

--- Registers the runtime systems selected by this project.
---@param register table Project configuration exposing register_runtime_system.
function RuntimeConfiguration.register(register)
  assert(register ~= nil and type(register.register_runtime_system) == "function",
    "project runtime configuration requires a project configuration register")

  register:register_runtime_system("world_topology", function()
    return {
      --- Assigns the main map topology before other runtime systems initialize.
      ---@param self table Stateless initialization adapter.
      ---@param context table Loaded project and its Actrune runtime.
      initialize = function(self, context)
        local registry = context.project.resources.world_topology
        local topology = registry and registry:get("main")

        context.runtime.world:set_topology(topology)
      end
    }
  end, 50)

  register:register_runtime_system("animated_entity_visuals", function()
    return AnimatedEntityVisualRuntimeSystem.new({
      configuration_name = "projected_character_visuals"
    })
  end, 400)

  register:register_runtime_system("static_entity_visuals", function()
    return StaticEntityVisualRuntimeSystem.new({
      configuration_name = "projected_static_visuals"
    })
  end, 410)
end

return RuntimeConfiguration
