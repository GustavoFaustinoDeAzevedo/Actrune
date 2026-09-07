local EntityVisualBinding = {}
EntityVisualBinding.__index = EntityVisualBinding

-- Associates an entity with a visual and an optional elevation component.
function EntityVisualBinding.new(entity_id, visual, elevation_component)
  assert(type(entity_id) == "string" and entity_id ~= "",
    "entity visual binding requires a non-empty entity id")
  assert(visual ~= nil,
    "entity visual binding requires a visual resource")
  assert(elevation_component == nil
    or type(elevation_component) == "string" and elevation_component ~= "",
    "entity visual binding elevation component must be a non-empty name")

  return setmetatable({
    entity_id = entity_id,
    visual = visual,
    elevation_component = elevation_component
  }, EntityVisualBinding)
end

-- Returns the id of the represented entity.
function EntityVisualBinding:get_entity_id()
  return self.entity_id
end

-- Returns the associated visual resource.
function EntityVisualBinding:get_visual()
  return self.visual
end

-- Returns the optional component name supplying world-space elevation.
function EntityVisualBinding:get_elevation_component()
  return self.elevation_component
end

return EntityVisualBinding
