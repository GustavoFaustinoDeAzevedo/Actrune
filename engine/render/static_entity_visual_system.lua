local StaticEntityVisual = require("engine.render.static_entity_visual")

local StaticEntityVisualSystem = {}
StaticEntityVisualSystem.__index = StaticEntityVisualSystem

-- Creates runtime static entity visuals from an indexed binding collection.
function StaticEntityVisualSystem.new(entities_by_id, bindings)
  assert(type(entities_by_id) == "table",
    "static entity visual system requires entities_by_id")
  assert(bindings ~= nil and type(bindings.get_count) == "function",
    "static entity visual system requires a binding collection exposing get_count")
  assert(type(bindings.get) == "function",
    "static entity visual system requires a binding collection exposing get")

  -- This table stores the runtime representations created from declarative bindings.
  local visuals = {}

  for index = 1, bindings:get_count() do
    local binding = bindings:get(index)

    assert(binding ~= nil and type(binding.get_entity_id) == "function",
      "static entity visual system binding must expose get_entity_id")
    assert(type(binding.get_visual) == "function",
      "static entity visual system binding must expose get_visual")

    local entity_id = binding:get_entity_id()
    local entity = entities_by_id[entity_id]

    assert(entity ~= nil,
      "static visual binding references an unloaded entity: " .. entity_id)

    -- Each runtime representation combines one live entity with one shared stateless visual.
    visuals[index] = StaticEntityVisual.new(
      entity_id,
      entity,
      binding:get_visual()
    )
  end

  return setmetatable({
    visuals = visuals
  }, StaticEntityVisualSystem)
end

-- Returns the number of static runtime representations owned by this system.
function StaticEntityVisualSystem:get_count()
  return #self.visuals
end

-- Returns one static runtime representation by its one-based index.
function StaticEntityVisualSystem:get(index)
  assert(type(index) == "number" and index % 1 == 0,
    "static entity visual system index must be an integer")
  assert(index >= 1 and index <= #self.visuals,
    "static entity visual system index is out of range")

  return self.visuals[index]
end

return StaticEntityVisualSystem
