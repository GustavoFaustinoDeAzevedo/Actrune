local EntityVisualBinding = {}
EntityVisualBinding.__index = EntityVisualBinding

-- Creates a declarative association between one entity id and one visual template.
function EntityVisualBinding.new(entity_id, visual_template)
  assert(type(entity_id) == "string" and entity_id ~= "",
    "entity visual binding requires a non-empty entity id")
  assert(visual_template ~= nil,
    "entity visual binding requires a visual template")

  return setmetatable({
    entity_id = entity_id,
    visual_template = visual_template
  }, EntityVisualBinding)
end

-- Returns the id of the entity represented by this binding.
function EntityVisualBinding:get_entity_id()
  return self.entity_id
end

-- Returns the reusable visual template associated with the entity.
function EntityVisualBinding:get_visual_template()
  return self.visual_template
end

return EntityVisualBinding