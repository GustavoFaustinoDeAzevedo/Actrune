local EntityVisual = require("engine.render.entity_visual")
local EntityVisualCollection = require("engine.render.entity_visual_collection")

local StaticEntityVisualSystem = {}
StaticEntityVisualSystem.__index = StaticEntityVisualSystem

-- Creates entity representations that directly share their drawable resources.
function StaticEntityVisualSystem.new(entities_by_id, bindings)
  local collection = EntityVisualCollection.new(
    entities_by_id,
    bindings,
    EntityVisual.new
  )

  return setmetatable({
    collection = collection
  }, StaticEntityVisualSystem)
end

-- Returns the number of runtime representations.
function StaticEntityVisualSystem:get_count()
  return self.collection:get_count()
end

-- Returns one runtime representation by its one-based index.
function StaticEntityVisualSystem:get(index)
  return self.collection:get(index)
end

return StaticEntityVisualSystem
