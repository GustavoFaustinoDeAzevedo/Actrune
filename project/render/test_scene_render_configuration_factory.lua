local TestSceneRenderConfiguration = require("project.render.test_scene_render_configuration")

local TestSceneRenderConfigurationFactory = {}

-- Creates a test scene render configuration from its serialized project definition.
function TestSceneRenderConfigurationFactory.create(definition, context)
  assert(type(definition) == "table",
    "test scene render configuration definition must be a table")
  assert(context ~= nil and type(context.resolve_resource) == "function",
    "test scene render configuration factory requires resource resolution")

  local ground_levels = context.resolve_resource(
    "spatial_levels",
    definition.ground_levels
  )

  -- The runtime configuration keeps validation and access separate from serialized project data.
  return TestSceneRenderConfiguration.new({
    -- Camera target associations remain serialized as entity ids.
    world_camera_target_entity = definition.world_camera_target_entity,
    projected_camera_target_entity = definition.projected_camera_target_entity,

    world_camera_position_half_life = definition.world_camera_position_half_life,
    projected_camera_position_half_life = definition.projected_camera_position_half_life,
    projected_camera_rotation_half_life = definition.projected_camera_rotation_half_life,
    projected_camera_forward_offset = definition.projected_camera_forward_offset,

    camera_elevation = definition.camera_elevation,
    reference_distance = definition.reference_distance,

    ground_region_width = definition.ground_region_width,
    ground_region_height = definition.ground_region_height,
    ground_levels = ground_levels,
    ground_level = definition.ground_level,

    horizon = definition.horizon,
    near_distance = definition.near_distance,
    far_distance = definition.far_distance,
    horizontal_fov = definition.horizontal_fov
  })
end

return TestSceneRenderConfigurationFactory
