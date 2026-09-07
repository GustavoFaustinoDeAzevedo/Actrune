local CircleShape = require("engine.world.spatial.circle_shape")
local PolygonShape = require("engine.world.spatial.polygon_shape")

local RigidBody = require("engine.world.physics.rigid_body")

local GridContext = require("engine.world.grid.grid_context")
local GridArea = require("engine.world.grid.grid_area")

local FacingDirection = require("engine.world.movement.direction.facing_direction")

local TranslationControl = require("engine.world.control.translation_control")
local RotationControl = require("engine.world.control.rotation_control")
local SpatialActionControl = require("engine.world.control.spatial_action_control")
local SpatialElevation = require("engine.world.spatial.spatial_elevation")
local VerticalRange = require("engine.world.spatial.vertical_range")

local ActruneEntityTypes = {}

-- Registers the built-in Actrune shape and component families in a type catalog.
function ActruneEntityTypes.register(catalog)
  assert(catalog ~= nil, "Actrune entity types require a type catalog")

  catalog:ensure_registry("shape", { kind = "shape" })
  catalog:ensure_registry("component", { kind = "component" })

  catalog:register("component", "vertical_range", function(definition)
    return VerticalRange.new({
      elevation_component = definition.elevation_component,
      lower = definition.lower,
      upper = definition.upper
    })
  end, {
    fields = {
      { name = "elevation_component", type = "string", optional = true },
      { name = "lower",               type = "number", required = true },
      { name = "upper",               type = "number", required = true }
    }
  })

  catalog:register("component", "spatial_elevation", function(definition, context)
    local levels = context.factory:get_resource("spatial_levels", definition.levels)

    assert(levels ~= nil,
      "unknown spatial levels resource: " .. tostring(definition.levels))

    return SpatialElevation.new({
      levels = levels,
      level = definition.level,
      offset = definition.offset
    })
  end, {
    fields = {
      {
        name = "levels",
        type = "resource_reference",
        resource_type = "spatial_levels",
        required = true
      },
      { name = "level",  type = "integer", min = 0,    default = 0 },
      { name = "offset", type = "number",  default = 0 }
    }
  })

  catalog:register("shape", "circle", function(definition, context)
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

  catalog:register("shape", "polygon", function(definition, context)
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

  catalog:register("component", "rigid_body", function(definition)
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

  catalog:register("component", "controls", function(definition, context)
    local profile = context.factory:get_resource("control_profile", definition.profile)
    assert(profile ~= nil, "unknown control profile: " .. tostring(definition.profile))
    return profile
  end, {
    fields = {
      { name = "profile", type = "resource_reference", resource_type = "control_profile", required = true }
    }
  })

  catalog:register("component", "grid_context", function(definition, context)
    local metrics = nil

    if definition.metrics ~= nil then
      metrics = context.factory:get_resource("grid_metrics", definition.metrics)
      assert(metrics ~= nil, "unknown grid metrics resource: " .. tostring(definition.metrics))
    end

    return GridContext.new({ metrics = metrics })
  end, {
    fields = {
      { name = "metrics", type = "resource_reference", resource_type = "grid_metrics", optional = true }
    }
  })

  catalog:register("component", "grid_area", function(definition, context)
    local metrics = nil

    if definition.metrics ~= nil then
      metrics = context.factory:get_resource("grid_metrics", definition.metrics)
      assert(metrics ~= nil, "unknown grid metrics resource: " .. tostring(definition.metrics))
    end

    return GridArea.new({
      shape = definition.shape,
      metrics = metrics,
      priority = definition.priority
    })
  end, {
    fields = {
      { name = "shape",    type = "shape_reference",    required = true },
      { name = "metrics",  type = "resource_reference", resource_type = "grid_metrics", optional = true },
      { name = "priority", type = "number",             default = 0 }
    }
  })

  catalog:register("component", "facing_direction", function()
    return FacingDirection.new()
  end, {
    fields = {}
  })

  catalog:register("component", "translation_control", function(definition, context)
    local factory_context = { factory = context.factory }

    return TranslationControl.new({
      controls = definition.controls,
      input = definition.input,
      direction = definition.direction,
      direction_policy = context.catalog:create("direction_policy", definition.direction_policy or { type = "identity" },
        factory_context),
      displacement = context.catalog:create("displacement_expression", definition.displacement, factory_context),
      application = context.catalog:create("control_application", definition.application, factory_context),
      source_shape = definition.source_shape,
      target_shape = definition.target_shape
    })
  end, {
    fields = {
      { name = "controls",         type = "string",                  default = "controls" },
      { name = "input",            type = "string",                  required = true },
      { name = "direction",        type = "string",                  required = true },
      { name = "direction_policy", type = "direction_policy",        optional = true },
      { name = "displacement",     type = "displacement_expression", required = true },
      { name = "application",      type = "control_application",     required = true },
      { name = "source_shape",     type = "shape_reference",         required = true },
      { name = "target_shape",     type = "shape_reference",         required = true }
    }
  })

  catalog:register("component", "rotation_control", function(definition, context)
    local factory_context = { factory = context.factory }

    return RotationControl.new({
      controls = definition.controls,
      input = definition.input,
      amount = context.catalog:create("value_expression", definition.amount, factory_context),
      application = context.catalog:create("control_application", definition.application, factory_context)
    })
  end, {
    fields = {
      { name = "controls",    type = "string",              default = "controls" },
      { name = "input",       type = "string",              required = true },
      { name = "amount",      type = "value_expression",    required = true },
      { name = "application", type = "control_application", required = true }
    }
  })

  catalog:register("component", "spatial_action_control", function(definition)
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
end

return ActruneEntityTypes
