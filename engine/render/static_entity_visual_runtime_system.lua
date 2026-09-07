local StaticEntityVisualSystem = require("engine.render.static_entity_visual_system")

local StaticEntityVisualRuntimeSystem = {}
StaticEntityVisualRuntimeSystem.__index = StaticEntityVisualRuntimeSystem

-- Creates a runtime adapter for one named static entity visual configuration.
function StaticEntityVisualRuntimeSystem.new(options)
  options = options or {}

  assert(type(options.configuration_name) == "string" and options.configuration_name ~= "",
    "static entity visual runtime system requires a non-empty configuration name")

  return setmetatable({
    configuration_name = options.configuration_name,
    system = nil
  }, StaticEntityVisualRuntimeSystem)
end

-- Initializes static entity visuals from the configured project resource.
function StaticEntityVisualRuntimeSystem:initialize(context)
  local configurations = context.project.resources["static_entity_visual_configuration"]

  assert(configurations ~= nil,
    "static entity visual runtime system requires static_entity_visual_configuration resources")

  local configuration = configurations:get(self.configuration_name)

  assert(configuration ~= nil,
    "static entity visual configuration does not exist: " .. self.configuration_name)

  self.system = StaticEntityVisualSystem.new(
    context.project.entities_by_id,
    configuration:get_bindings()
  )
end

-- Returns the number of runtime static entity visuals.
function StaticEntityVisualRuntimeSystem:get_count()
  assert(self.system ~= nil, "static entity visual runtime system is not initialized")
  return self.system:get_count()
end

-- Returns one runtime static entity visual by its one-based index.
function StaticEntityVisualRuntimeSystem:get(index)
  assert(self.system ~= nil, "static entity visual runtime system is not initialized")
  return self.system:get(index)
end

return StaticEntityVisualRuntimeSystem
