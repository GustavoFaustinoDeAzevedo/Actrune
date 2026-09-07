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
    assert(type(binding.get_elevation_component) == "function",
      "entity visual collection binding must expose get_elevation_component")

    local entity_id = binding:get_entity_id()
    local entity = entities_by_id[entity_id]

    assert(entity ~= nil,
      "entity visual binding references an unloaded entity: " .. entity_id)

    local elevation_source = nil
    local component_name = binding:get_elevation_component()

    if component_name ~= nil then
      assert(type(entity.get_component) == "function",
        "entity visual elevation requires an entity exposing get_component")

      elevation_source = entity:get_component(component_name)

      assert(elevation_source ~= nil,
        "entity visual references a missing component: " .. entity_id .. "." .. component_name)
      assert(type(elevation_source.get_elevation) == "function",
        "entity visual elevation component must expose get_elevation")
    end

    -- Resolve shared dependencies before selecting the concrete representation.
    local entity_visual = representation_factory(
      entity_id,
      entity,
      binding:get_visual(),
      elevation_source
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
