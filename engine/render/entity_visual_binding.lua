local EntityVisualBinding = {}
EntityVisualBinding.__index = EntityVisualBinding

-- Creates a declarative association between one entity id and one visual resource.
function EntityVisualBinding.new(entity_id, visual)
  assert(type(entity_id) == "string" and entity_id ~= "",
    "entity visual binding requires a non-empty entity id")
  assert(visual ~= nil,
    "entity visual binding requires a visual resource")

  -- The binding stores only the association and does not own runtime visual state.
  return setmetatable({
    entity_id = entity_id,
    visual = visual
  }, EntityVisualBinding)
end

-- Returns the id of the entity represented by this binding.
function EntityVisualBinding:get_entity_id()
  return self.entity_id
end

-- Returns the visual resource associated with the entity.
function EntityVisualBinding:get_visual()
  return self.visual
end

return EntityVisualBinding
