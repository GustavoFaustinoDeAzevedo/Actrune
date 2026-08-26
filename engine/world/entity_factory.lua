local Entity = require("engine.world.entity")
local CircleShape = require("engine.world.spatial.circle_shape")
local PolygonShape = require("engine.world.spatial.polygon_shape")
local RigidBody = require("engine.world.physics.rigid_body")
local DefinitionRegistry = require("engine.core.definitions.definition_registry")
local FacingDirection = require("engine.world.movement.direction.facing_direction")
local TranslationControl = require("engine.world.control.translation_control")
local RotationControl = require("engine.world.control.rotation_control")
local SpatialActionControl = require("engine.world.control.spatial_action_control")
local ValueExpressionFactory = require("engine.core.values.value_expression_factory")
local ControlApplicationFactory = require("engine.world.control.control_application_factory")
local GridContext = require("engine.world.grid.grid_context")
local GridArea = require("engine.world.grid.grid_area")

local EntityFactory = {}
EntityFactory.__index = EntityFactory

-- Creates an entity factory with built-in Actrune shape and component types.
function EntityFactory.new(definitions, event_factory)
  local self = setmetatable({}, EntityFactory)

  self.shape_builders = {}
  self.component_builders = {}
  self.resources = {}
  self.definitions = definitions or DefinitionRegistry.new()
  self.event_factory = event_factory

  self:register_shape_type("circle", function(definition, context)
    return CircleShape.new({
      radius = definition.radius,
      offset_x = definition.offset_x,
      offset_y = definition.offset_y,
      segments = definition.segments,
      material = context.material
    })
  end, {
    fields = {
      { name = "radius",   type = "number",             required = true,                     min_exclusive = 0 },
      { name = "offset_x", type = "number",             default = 0 },
      { name = "offset_y", type = "number",             default = 0 },
      { name = "segments", type = "integer",            default = 24,                        min = 3 },
      { name = "material", type = "resource_reference", resource_type = "physical_material", optional = true }
    }
  })

  self:register_shape_type("polygon", function(definition, context)
    return PolygonShape.new({
      points = definition.points,
      offset_x = definition.offset_x,
      offset_y = definition.offset_y,
      material = context.material
    })
  end, {
    fields = {
      { name = "points",   type = "point_list",         required = true,                     min_items = 3 },
      { name = "offset_x", type = "number",             default = 0 },
      { name = "offset_y", type = "number",             default = 0 },
      { name = "material", type = "resource_reference", resource_type = "physical_material", optional = true }
    }
  })

  self:register_component_type("rigid_body", function(definition)
    return RigidBody.new({
      body_type = definition.body_type,
      shapes = definition.shapes
    })
  end, {
    fields = {
      { name = "body_type", type = "enum",                 default = "static", values = { "static", "dynamic", "kinematic" } },
      { name = "shapes",    type = "shape_reference_list", required = true }
    }
  })

  self:register_component_type("controls", function(definition, context)
    local profile = context.factory:get_resource("control_profile", definition.profile)
    assert(profile ~= nil, "unknown control profile: " .. tostring(definition.profile))
    return profile
  end, {
    fields = {
      { name = "profile", type = "resource_reference", resource_type = "control_profile", required = true }
    }
  })

  self:register_component_type("grid_context", function(definition, context)
    local metrics = context.factory:get_resource("grid_metrics", definition.metrics)
    assert(metrics ~= nil, "unknown grid metrics resource: " .. tostring(definition.metrics))

    return GridContext.new({
      metrics = metrics
    })
  end, {
    fields = {
      { name = "metrics", type = "resource_reference", resource_type = "grid_metrics", required = true }
    }
  })

  self:register_component_type("grid_area", function(definition, context)
    local metrics = context.factory:get_resource("grid_metrics", definition.metrics)
    assert(metrics ~= nil, "unknown grid metrics resource: " .. tostring(definition.metrics))

    return GridArea.new({
      shape = definition.shape,
      metrics = metrics,
      priority = definition.priority
    })
  end, {
    fields = {
      { name = "shape",    type = "shape_reference",    required = true },
      { name = "metrics",  type = "resource_reference", resource_type = "grid_metrics", required = true },
      { name = "priority", type = "number",             default = 0 }
    }
  })

  self:register_component_type("facing_direction", function()
    return FacingDirection.new()
  end, {
    fields = {}
  })

  self:register_component_type("translation_control", function(definition, context)
    return TranslationControl.new({
      controls = definition.controls,
      input = definition.input,
      direction = definition.direction,
      amount = ValueExpressionFactory.create(definition.amount, {
        factory = context.factory
      }),
      application = ControlApplicationFactory.create(definition.application),
      source_shape = definition.source_shape,
      target_shape = definition.target_shape
    })
  end, {
    fields = {
      { name = "controls",     type = "string",              default = "controls" },
      { name = "input",        type = "string",              required = true },
      { name = "direction",    type = "string",              required = true },
      { name = "amount",       type = "value_expression",    required = true },
      { name = "application",  type = "control_application", required = true },
      { name = "source_shape", type = "shape_reference",     required = true },
      { name = "target_shape", type = "shape_reference",     required = true }
    }
  })

  self:register_component_type("rotation_control", function(definition, context)
    return RotationControl.new({
      controls = definition.controls,
      input = definition.input,
      amount = ValueExpressionFactory.create(definition.amount, {
        factory = context.factory
      }),
      application = ControlApplicationFactory.create(definition.application)
    })
  end, {
    fields = {
      { name = "controls",    type = "string",              default = "controls" },
      { name = "input",       type = "string",              required = true },
      { name = "amount",      type = "value_expression",    required = true },
      { name = "application", type = "control_application", required = true }
    }
  })

  self:register_component_type("spatial_action_control", function(definition)
    return SpatialActionControl.new({
      controls = definition.controls,
      input = definition.input
    })
  end, {
    fields = {
      { name = "controls", type = "string", default = "controls" },
      { name = "input",    type = "string", required = true }
    }
  })

  return self
end

-- Registers a builder and optional metadata for a named spatial shape type.
function EntityFactory:register_shape_type(type_name, builder, definition)
  assert(type(type_name) == "string", "shape type name must be a string")
  assert(type(builder) == "function", "shape builder must be a function")

  self.shape_builders[type_name] = builder

  if definition ~= nil and not self.definitions:has("shape", type_name) then
    self.definitions:register("shape", type_name, definition)
  end
end

-- Registers a builder and optional metadata for a named component type.
function EntityFactory:register_component_type(type_name, builder, definition)
  assert(type(type_name) == "string", "component type name must be a string")
  assert(type(builder) == "function", "component builder must be a function")

  self.component_builders[type_name] = builder

  if definition ~= nil and not self.definitions:has("component", type_name) then
    self.definitions:register("component", type_name, definition)
  end
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

-- Returns the definition registry used by this factory.
function EntityFactory:get_definitions()
  return self.definitions
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
    material = material,
    factory = self
  })
end

-- Builds one component from its serializable definition.
function EntityFactory:_build_component(definition)
  assert(type(definition) == "table", "component definition must be a table")
  assert(type(definition.type) == "string", "component definition requires a type")

  local builder = self.component_builders[definition.type]
  assert(builder ~= nil, "unknown component type: " .. definition.type)

  return builder(definition, {
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
