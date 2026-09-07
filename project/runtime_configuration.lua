local AnimatedEntityVisualRuntimeSystem = require("engine.render.animated_entity_visual_runtime_system")
local StaticEntityVisualRuntimeSystem = require("engine.render.static_entity_visual_runtime_system")

local RuntimeConfiguration = {}

-- Registers runtime systems required specifically by the current project.
function RuntimeConfiguration.register(register)
  assert(register ~= nil and type(register.register_runtime_system) == "function",
    "project runtime configuration requires a project configuration register")

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
