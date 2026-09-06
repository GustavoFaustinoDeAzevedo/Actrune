local StaticEntityVisual = require("engine.render.static_entity_visual")
local EntityVisualCollection = require("engine.render.entity_visual_collection")

local StaticEntityVisualSystem = {}
StaticEntityVisualSystem.__index = StaticEntityVisualSystem

-- Creates one static entity visual representation from resolved binding data.
local function create_static_visual(entity_id, entity, visual)
  -- Static representations directly share their stateless visual resource.
  return StaticEntityVisual.new(
    entity_id,
    entity,
    visual
  )
end

-- Creates runtime static entity visuals from an indexed binding collection.
function StaticEntityVisualSystem.new(entities_by_id, bindings)
  assert(type(entities_by_id) == "table",
    "static entity visual system requires entities_by_id")

  -- The generic collection handles binding resolution while this system selects the static representation type.
  local collection = EntityVisualCollection.new(
    entities_by_id,
    bindings,
    create_static_visual
  )

  return setmetatable({
    collection = collection
  }, StaticEntityVisualSystem)
end

-- Returns the number of static runtime representations owned by this system.
function StaticEntityVisualSystem:get_count()
  return self.collection:get_count()
end

-- Returns one static runtime representation by its one-based index.
function StaticEntityVisualSystem:get(index)
  return self.collection:get(index)
end

return StaticEntityVisualSystem
