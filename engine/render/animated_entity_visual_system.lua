local AnimatedEntityVisual = require("engine.render.animated_entity_visual")

local AnimatedEntityVisualSystem = {}
AnimatedEntityVisualSystem.__index = AnimatedEntityVisualSystem

-- Creates a runtime collection of animated entity visuals from declarative bindings.
function AnimatedEntityVisualSystem.new(entities_by_id, bindings)
  assert(type(entities_by_id) == "table",
    "animated entity visual system requires entities_by_id")
  assert(bindings ~= nil and type(bindings.get_count) == "function" and type(bindings.get) == "function",
    "animated entity visual system requires an indexed binding collection")

  local self = setmetatable({
    visuals = {}
  }, AnimatedEntityVisualSystem)

  for index = 1, bindings:get_count() do
    local binding = bindings:get(index)

    assert(binding ~= nil and type(binding.get_entity_id) == "function",
      "animated entity visual system binding must expose get_entity_id")
    assert(type(binding.get_visual_template) == "function",
      "animated entity visual system binding must expose get_visual_template")

    local entity_id = binding:get_entity_id()
    local entity = entities_by_id[entity_id]

    assert(entity ~= nil,
      "visual binding references an unloaded entity: " .. entity_id)

    self.visuals[index] = AnimatedEntityVisual.new(
      entity_id,
      entity,
      binding:get_visual_template()
    )
  end

  return self
end

-- Returns the number of runtime visual instances owned by this system.
function AnimatedEntityVisualSystem:get_count()
  return #self.visuals
end

-- Returns one runtime visual instance by its one-based index.
function AnimatedEntityVisualSystem:get(index)
  assert(type(index) == "number" and index % 1 == 0,
    "animated entity visual system index must be an integer")
  assert(index >= 1 and index <= #self.visuals,
    "animated entity visual system index is out of range")

  return self.visuals[index]
end

-- Updates every animated entity visual owned by this system.
function AnimatedEntityVisualSystem:update(dt)
  for _, entity_visual in ipairs(self.visuals) do
    entity_visual:update(dt)
  end
end

return AnimatedEntityVisualSystem
