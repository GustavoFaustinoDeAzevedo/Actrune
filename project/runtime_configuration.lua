local AnimatedEntityVisualRuntimeSystem = require("engine.render.animated_entity_visual_runtime_system")

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
end

return RuntimeConfiguration
