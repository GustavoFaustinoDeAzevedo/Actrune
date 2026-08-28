local Entity = require("engine.world.entity")

local EntityFactory = {}
EntityFactory.__index = EntityFactory

-- Creates an entity factory backed by an extensible project type catalog.
function EntityFactory.new(event_factory, type_catalog)
  local self = setmetatable({}, EntityFactory)

  self.resources = {}
  self.event_factory = event_factory
  self.type_catalog = type_catalog

  assert(self.type_catalog ~= nil, "entity factory requires a type catalog")
  assert(self.type_catalog:has_registry("shape"), "entity factory requires a shape registry")
  assert(self.type_catalog:has_registry("component"), "entity factory requires a component registry")

  return self
end

-- Registers a shape type in the entity factory's project type catalog.
function EntityFactory:register_shape_type(type_name, builder, definition)
  self.type_catalog:register("shape", type_name, builder, definition)
end

-- Registers a component type in the entity factory's project type catalog.
function EntityFactory:register_component_type(type_name, builder, definition)
  self.type_catalog:register("component", type_name, builder, definition)
end

-- Registers a named resource registry available to entity builders.
function EntityFactory:register_resource_type(type_name, registry)
  assert(type(type_name) == "string", "resource type name must be a string")
  assert(registry ~= nil, "resource registry is required")
  self.resources[type_name] = registry
end

-- Returns a resource from a named registry.
function EntityFactory:get_resource(type_name, name)
  if name == nil then return nil end

  local registry = self.resources[type_name]
  if registry == nil then return nil end

  return registry:get(name)
end

-- Builds one spatial shape from its serializable definition.
function EntityFactory:_build_shape(definition)
  assert(type(definition) == "table", "shape definition must be a table")
  assert(type(definition.type) == "string", "shape definition requires a type")

  local material = nil

  if definition.material ~= nil then
    material = self:get_resource("physical_material", definition.material)
    assert(material ~= nil, "unknown physical material: " .. tostring(definition.material))
  end

  return self.type_catalog:create("shape", definition, {
    factory = self,
    material = material
  })
end

-- Builds one component from its serializable definition.
function EntityFactory:_build_component(definition)
  assert(type(definition) == "table", "component definition must be a table")
  assert(type(definition.type) == "string", "component definition requires a type")

  return self.type_catalog:create("component", definition, {
    factory = self
  })
end

-- Adds all serialized events to a newly created runtime entity.
function EntityFactory:_build_events(entity, definitions)
  if #definitions == 0 then return end

  assert(self.event_factory ~= nil, "entity contains events but no event factory is configured")

  for _, definition in ipairs(definitions) do
    entity:add_event(self.event_factory:create(definition))
  end
end

-- Creates a runtime entity from a serializable entity definition.
function EntityFactory:create(definition)
  assert(type(definition) == "table", "entity definition must be a table")
  assert(type(definition.id) == "string", "entity definition requires an id")

  local transform = definition.transform or {}
  local shapes = {}
  local components = {}

  for name, shape_definition in pairs(definition.shapes or {}) do
    shapes[name] = self:_build_shape(shape_definition)
  end

  for name, component_definition in pairs(definition.components or {}) do
    components[name] = self:_build_component(component_definition)
  end

  local entity = Entity.new({
    id = definition.id,
    x = transform.x,
    y = transform.y,
    rotation = transform.rotation,
    scale_x = transform.scale_x,
    scale_y = transform.scale_y,
    shapes = shapes,
    components = components
  })

  self:_build_events(entity, definition.events or {})

  return entity
end

return EntityFactory
