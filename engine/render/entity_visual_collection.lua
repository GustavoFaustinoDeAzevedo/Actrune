local EntityVisualCollection = {}
EntityVisualCollection.__index = EntityVisualCollection

-- Creates runtime entity visuals from bindings using an injected representation factory.
function EntityVisualCollection.new(entities_by_id, bindings, representation_factory)
  assert(type(entities_by_id) == "table",
    "entity visual collection requires entities_by_id")
  assert(bindings ~= nil and type(bindings.get_count) == "function",
    "entity visual collection requires a binding collection exposing get_count")
  assert(type(bindings.get) == "function",
    "entity visual collection requires a binding collection exposing get")
  assert(type(representation_factory) == "function",
    "entity visual collection requires a representation factory")

  -- This table preserves the binding order used by the project configuration.
  local visuals = {}

  for index = 1, bindings:get_count() do
    local binding = bindings:get(index)

    assert(binding ~= nil and type(binding.get_entity_id) == "function",
      "entity visual collection binding must expose get_entity_id")
    assert(type(binding.get_visual) == "function",
      "entity visual collection binding must expose get_visual")

    local entity_id = binding:get_entity_id()
    local entity = entities_by_id[entity_id]

    assert(entity ~= nil,
      "entity visual binding references an unloaded entity: " .. entity_id)

    -- The collection resolves common binding data while the injected factory chooses the representation type.
    local entity_visual = representation_factory(
      entity_id,
      entity,
      binding:get_visual()
    )

    assert(entity_visual ~= nil,
      "entity visual representation factory must return a visual instance")

    visuals[index] = entity_visual
  end

  return setmetatable({
    visuals = visuals
  }, EntityVisualCollection)
end

-- Returns the number of runtime representations in this collection.
function EntityVisualCollection:get_count()
  return #self.visuals
end

-- Returns one runtime representation by its one-based index.
function EntityVisualCollection:get(index)
  assert(type(index) == "number" and index % 1 == 0,
    "entity visual collection index must be an integer")
  assert(index >= 1 and index <= #self.visuals,
    "entity visual collection index is out of range")

  return self.visuals[index]
end

return EntityVisualCollection
