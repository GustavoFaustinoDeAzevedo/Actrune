local EntityVisual = {}
EntityVisual.__index = EntityVisual

-- Associates a live entity with a drawable representation and optional elevation.
function EntityVisual.new(entity_id, entity, visual, elevation_source)
  assert(type(entity_id) == "string" and entity_id ~= "",
    "entity visual requires a non-empty entity id")
  assert(entity ~= nil,
    "entity visual requires an entity")
  assert(type(entity.get_position) == "function",
    "entity visual entity must expose get_position")
  assert(type(entity.get_rotation) == "function",
    "entity visual entity must expose get_rotation")
  assert(visual ~= nil and type(visual.draw) == "function",
    "entity visual requires a drawable visual")
  assert(elevation_source == nil or type(elevation_source.get_elevation) == "function",
    "entity visual elevation source must expose get_elevation")

  return setmetatable({
    entity_id = entity_id,
    entity = entity,
    visual = visual,
    elevation_source = elevation_source
  }, EntityVisual)
end

-- Returns the id of the represented entity.
function EntityVisual:get_entity_id()
  return self.entity_id
end

-- Returns the represented entity.
function EntityVisual:get_entity()
  return self.entity
end

-- Returns the drawable representation.
function EntityVisual:get_visual()
  return self.visual
end

-- Returns the current world position of the represented entity.
function EntityVisual:get_position()
  return self.entity:get_position()
end

-- Returns the current world rotation of the represented entity.
function EntityVisual:get_rotation()
  return self.entity:get_rotation()
end

-- Returns live world-space elevation, defaulting to the base plane.
function EntityVisual:get_elevation()
  if self.elevation_source == nil then return 0 end
  return self.elevation_source:get_elevation()
end

return EntityVisual
