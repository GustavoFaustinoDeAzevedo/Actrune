local Entity = require("engine.world.entity")
local CircleShape = require("engine.world.spatial.circle_shape")
local PolygonShape = require("engine.world.spatial.polygon_shape")
local RigidBody = require("engine.world.physics.rigid_body")

local EntityFactory = {}
EntityFactory.__index = EntityFactory

-- Creates an entity factory with the built-in Actrune shape and component types.
function EntityFactory.new()
  local self = setmetatable({}, EntityFactory)

  self.shape_builders = {}
  self.component_builders = {}
  self.resources = {}

  self:register_shape_type("circle", function(definition, context)
    return CircleShape.new({
      radius = definition.radius,
      offset_x = definition.offset_x,
      offset_y = definition.offset_y,
      segments = definition.segments,
      material = context.material
    })
  end)

  self:register_shape_type("polygon", function(definition, context)
    return PolygonShape.new({
      points = definition.points,
      offset_x = definition.offset_x,
      offset_y = definition.offset_y,
      material = context.material
    })
  end)

  self:register_component_type("rigid_body", function(definition)
    return RigidBody.new({
      body_type = definition.body_type,
      shapes = definition.shapes
    })
  end)

  return self
end

-- Registers a builder for a named spatial shape type.
function EntityFactory:register_shape_type(type_name, builder)
  assert(type(type_name) == "string", "shape type name must be a string")
  assert(type(builder) == "function", "shape builder must be a function")
  self.shape_builders[type_name] = builder
end

-- Registers a builder for a named component type.
function EntityFactory:register_component_type(type_name, builder)
  assert(type(type_name) == "string", "component type name must be a string")
  assert(type(builder) == "function", "component builder must be a function")
  self.component_builders[type_name] = builder
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

  local builder = self.shape_builders[definition.type]
  assert(builder ~= nil, "unknown shape type: " .. definition.type)

  local material = nil

  if definition.material ~= nil then
    material = self:get_resource("physical_material", definition.material)
    assert(material ~= nil, "unknown physical material: " .. tostring(definition.material))
  end

  return builder(definition, {
    material = material
  })
end

-- Builds one component from its serializable definition.
function EntityFactory:_build_component(definition)
  assert(type(definition) == "table", "component definition must be a table")
  assert(type(definition.type) == "string", "component definition requires a type")

  local builder = self.component_builders[definition.type]
  assert(builder ~= nil, "unknown component type: " .. definition.type)

  return builder(definition)
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

  return Entity.new({
    id = definition.id,
    x = transform.x,
    y = transform.y,
    rotation = transform.rotation,
    scale_x = transform.scale_x,
    scale_y = transform.scale_y,
    shapes = shapes,
    components = components
  })
end

return EntityFactory
