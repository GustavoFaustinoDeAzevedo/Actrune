local TestSceneRenderConfiguration = require("project.render.test_scene_render_configuration")

local TestSceneRenderConfigurationFactory = {}

-- Creates a test scene render configuration from its serialized project definition.
function TestSceneRenderConfigurationFactory.create(definition)
  assert(type(definition) == "table",
    "test scene render configuration definition must be a table")

  -- The runtime configuration keeps validation and access separate from serialized project data.
  return TestSceneRenderConfiguration.new({
    world_camera_position_half_life = definition.world_camera_position_half_life,
    projected_camera_position_half_life = definition.projected_camera_position_half_life,
    projected_camera_rotation_half_life = definition.projected_camera_rotation_half_life,
    projected_camera_forward_offset = definition.projected_camera_forward_offset,
    ground_region_width = definition.ground_region_width,
    ground_region_height = definition.ground_region_height,
    horizon = definition.horizon,
    near_distance = definition.near_distance,
    far_distance = definition.far_distance,
    horizontal_fov = definition.horizontal_fov
  })
end

return TestSceneRenderConfigurationFactory
