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
    world_camera_transition = definition.world_camera_transition_routes ~= nil
        and context.resolve_resource("map_camera_transition_routes", definition.world_camera_transition_routes)
        or definition.world_camera_transition ~= nil
        and context.resolve_resource("camera_transition", definition.world_camera_transition) or nil,
    world_camera_map_bounds = definition.world_camera_map_bounds ~= nil
        and context.resolve_resource("map_camera_bounds", definition.world_camera_map_bounds) or nil,
    world_camera_min_x = definition.world_camera_min_x,
    world_camera_min_y = definition.world_camera_min_y,
    world_camera_max_x = definition.world_camera_max_x,
    world_camera_max_y = definition.world_camera_max_y,
    world_camera_elevation_component = definition.world_camera_elevation_component,
    projected_camera_target_entity = definition.projected_camera_target_entity,

    world_camera_position_half_life = definition.world_camera_position_half_life,
    projected_camera_position_half_life = definition.projected_camera_position_half_life,
    projected_camera_rotation_half_life = definition.projected_camera_rotation_half_life,
    projected_camera_forward_offset = definition.projected_camera_forward_offset,

    camera_elevation = definition.camera_elevation,
    camera_elevation_component = definition.camera_elevation_component,
    camera_elevation_half_life = definition.camera_elevation_half_life,
    reference_distance = definition.reference_distance,

    render_mode = definition.render_mode,
    loop_visual_padding = definition.loop_visual_padding,
    orthographic_elevation_scale = definition.orthographic_elevation_scale,

    ground_region_width = definition.ground_region_width,
    ground_region_height = definition.ground_region_height,
    ground_levels = ground_levels,
    ground_level = definition.ground_level,

    horizon = definition.horizon,
    near_distance = definition.near_distance,
    far_distance = definition.far_distance,
    horizontal_fov = definition.horizontal_fov,

  })
end

return TestSceneRenderConfigurationFactory
