local AnimatedEntityVisual = require("engine.render.animated_entity_visual")
local EntityVisualCollection = require("engine.render.entity_visual_collection")

local AnimatedEntityVisualSystem = {}
AnimatedEntityVisualSystem.__index = AnimatedEntityVisualSystem

-- Creates one animated entity visual representation from resolved binding data.
local function create_animated_visual(entity_id, entity, visual)
  -- AnimatedEntityVisual adds independent playback state around the shared visual template.
  return AnimatedEntityVisual.new(
    entity_id,
    entity,
    visual
  )
end

-- Creates runtime animated entity visuals from one declarative visual configuration.
function AnimatedEntityVisualSystem.new(entities_by_id, configuration)
  assert(type(entities_by_id) == "table",
    "animated entity visual system requires entities_by_id")
  assert(configuration ~= nil and type(configuration.get_bindings) == "function",
    "animated entity visual system requires a configuration exposing get_bindings")

  -- The configuration chooses the binding sequence while the generic collection resolves its entities.
  local bindings = configuration:get_bindings()

  local collection = EntityVisualCollection.new(
    entities_by_id,
    bindings,
    create_animated_visual
  )

  return setmetatable({
    collection = collection
  }, AnimatedEntityVisualSystem)
end

-- Returns the number of animated runtime representations owned by this system.
function AnimatedEntityVisualSystem:get_count()
  return self.collection:get_count()
end

-- Returns one animated runtime representation by its one-based index.
function AnimatedEntityVisualSystem:get(index)
  return self.collection:get(index)
end

-- Advances every independently animated representation owned by this system.
function AnimatedEntityVisualSystem:update(dt)
  -- Animation lifecycle remains here instead of leaking into the generic entity visual collection.
  for index = 1, self.collection:get_count() do
    self.collection:get(index):update(dt)
  end
end

return AnimatedEntityVisualSystem
