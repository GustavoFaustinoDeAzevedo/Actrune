local StaticEntityVisual = {}
StaticEntityVisual.__index = StaticEntityVisual

-- Creates one runtime representation backed by a stateless visual resource.
function StaticEntityVisual.new(entity_id, entity, visual)
  assert(type(entity_id) == "string" and entity_id ~= "",
    "static entity visual requires a non-empty entity id")
  assert(entity ~= nil,
    "static entity visual requires an entity")
  assert(type(entity.get_position) == "function",
    "static entity visual entity must expose get_position")
  assert(type(entity.get_rotation) == "function",
    "static entity visual entity must expose get_rotation")
  assert(visual ~= nil and type(visual.draw) == "function",
    "static entity visual requires a drawable visual")

  -- Static representations share their visual resource because no playback state is stored in it.
  return setmetatable({
    entity_id = entity_id,
    entity = entity,
    visual = visual
  }, StaticEntityVisual)
end

-- Returns the id of the represented entity.
function StaticEntityVisual:get_entity_id()
  return self.entity_id
end

-- Returns the represented entity.
function StaticEntityVisual:get_entity()
  return self.entity
end

-- Returns the stateless visual used by this representation.
function StaticEntityVisual:get_visual()
  return self.visual
end

-- Returns the current world position of the represented entity.
function StaticEntityVisual:get_position()
  return self.entity:get_position()
end

-- Returns the current world rotation of the represented entity.
function StaticEntityVisual:get_rotation()
  return self.entity:get_rotation()
end

return StaticEntityVisual
