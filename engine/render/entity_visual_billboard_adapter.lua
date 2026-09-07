local EntityVisualBillboardAdapter = {}

-- Creates one projected billboard entry backed by an entity visual instance.
function EntityVisualBillboardAdapter.create(entity_visual)
  assert(entity_visual ~= nil, "entity visual billboard adapter requires an entity visual")
  assert(type(entity_visual.get_entity_id) == "function",
    "entity visual billboard adapter requires get_entity_id")
  assert(type(entity_visual.get_position) == "function",
    "entity visual billboard adapter requires get_position")
  assert(type(entity_visual.get_rotation) == "function",
    "entity visual billboard adapter requires get_rotation")
  assert(type(entity_visual.get_visual) == "function",
    "entity visual billboard adapter requires get_visual")
  assert(type(entity_visual.get_elevation) == "function",
    "entity visual billboard adapter requires get_elevation")

  local entity_id = entity_visual:get_entity_id()
  local visual = entity_visual:get_visual()

  assert(type(entity_id) == "string" and entity_id ~= "",
    "entity visual billboard adapter requires a non-empty entity id")
  assert(visual ~= nil and type(visual.draw) == "function",
    "entity visual billboard adapter requires a drawable visual")

  return {
    id = entity_id,
    position_provider = function()
      return entity_visual:get_position()
    end,
    rotation_provider = function()
      return entity_visual:get_rotation()
    end,
    elevation_provider = function()
      return entity_visual:get_elevation()
    end,
    visual = visual
  }
end

-- Creates projected billboard entries for every indexed entity visual in a collection.
function EntityVisualBillboardAdapter.create_all(entity_visuals)
  assert(entity_visuals ~= nil and type(entity_visuals.get_count) == "function",
    "entity visual billboard adapter requires a collection exposing get_count")
  assert(type(entity_visuals.get) == "function",
    "entity visual billboard adapter requires a collection exposing get")

  local entries = {}

  for index = 1, entity_visuals:get_count() do
    entries[index] = EntityVisualBillboardAdapter.create(entity_visuals:get(index))
  end

  return entries
end

return EntityVisualBillboardAdapter
