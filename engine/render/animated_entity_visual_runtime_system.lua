local AnimatedEntityVisualSystem = require("engine.render.animated_entity_visual_system")

local AnimatedEntityVisualRuntimeSystem = {}
AnimatedEntityVisualRuntimeSystem.__index = AnimatedEntityVisualRuntimeSystem

-- Creates a runtime adapter for one named animated entity visual configuration.
function AnimatedEntityVisualRuntimeSystem.new(options)
  options = options or {}

  assert(type(options.configuration_name) == "string" and options.configuration_name ~= "",
    "animated entity visual runtime system requires a non-empty configuration name")

  return setmetatable({
    configuration_name = options.configuration_name,
    system = nil
  }, AnimatedEntityVisualRuntimeSystem)
end

-- Initializes animated entity visuals from the configured project resource.
function AnimatedEntityVisualRuntimeSystem:initialize(context)
  local configurations = context.project.resources["animated_entity_visual_configuration"]

  assert(configurations ~= nil,
    "animated entity visual runtime system requires animated_entity_visual_configuration resources")

  local configuration = configurations:get(self.configuration_name)

  assert(configuration ~= nil,
    "animated entity visual configuration does not exist: " .. self.configuration_name)

  self.system = AnimatedEntityVisualSystem.new(
    context.project.entities_by_id,
    configuration
  )
end

-- Returns the number of runtime animated entity visuals.
function AnimatedEntityVisualRuntimeSystem:get_count()
  assert(self.system ~= nil, "animated entity visual runtime system is not initialized")
  return self.system:get_count()
end

-- Returns one runtime animated entity visual by its one-based index.
function AnimatedEntityVisualRuntimeSystem:get(index)
  assert(self.system ~= nil, "animated entity visual runtime system is not initialized")
  return self.system:get(index)
end

-- Returns the playback associated with one runtime representation index.
function AnimatedEntityVisualRuntimeSystem:get_animation(index)
  assert(self.system ~= nil, "animated entity visual runtime system is not initialized")
  return self.system:get_animation(index)
end

-- Updates every runtime animated entity visual.
function AnimatedEntityVisualRuntimeSystem:update(dt, context)
  self.system:update(dt)
end

return AnimatedEntityVisualRuntimeSystem
