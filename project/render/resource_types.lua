local TestSceneRenderConfigurationFactory =
    require("project.render.test_scene_render_configuration_factory")

local ProjectRenderResourceTypes = {}

-- Registers the render resource types owned specifically by the current project.
function ProjectRenderResourceTypes.register(register)
  assert(register ~= nil and type(register.register_resource_type) == "function",
    "project render resource types require a project configuration register")

  -- This resource keeps test-scene camera and projection values in project data instead of renderer code.
  register:register_resource_type(
    "test_scene_render_configuration",
    TestSceneRenderConfigurationFactory.create,
    {
      fields = {
        { name = "world_camera_transition_routes",      type = "resource_reference", resource_type = "map_camera_transition_routes", optional = true },
        { name = "world_camera_transition",             type = "resource_reference", resource_type = "camera_transition",            optional = true },
        { name = "world_camera_map_bounds",             type = "resource_reference", resource_type = "map_camera_bounds",            optional = true },
        { name = "loop_visual_padding",                 type = "number",             default = 1024,                                 min = 0 },
        { name = "world_camera_min_x",                  type = "number",             optional = true },
        { name = "world_camera_min_y",                  type = "number",             optional = true },
        { name = "world_camera_max_x",                  type = "number",             optional = true },
        { name = "world_camera_max_y",                  type = "number",             optional = true },
        { name = "world_camera_elevation_component",    type = "string",             optional = true },
        { name = "camera_elevation_component",          type = "string",             optional = true },
        { name = "camera_elevation_half_life",          type = "number",             default = 0.08,                                 min = 0 },
        { name = "render_mode",                         type = "enum",               values = { "perspective", "orthographic" },     required = true },
        { name = "orthographic_elevation_scale",        type = "number",             required = true,                                min = 0 },
        { name = "ground_levels",                       type = "resource_reference", resource_type = "spatial_levels",               required = true },
        { name = "ground_level",                        type = "integer",            required = true,                                min = 0 },
        { name = "camera_elevation",                    type = "number",             required = true },
        { name = "reference_distance",                  type = "number",             required = true,                                min_exclusive = 0 },
        { name = "world_camera_target_entity",          type = "entity_reference",   required = true },
        { name = "projected_camera_target_entity",      type = "entity_reference",   required = true },
        { name = "world_camera_position_half_life",     type = "number",             required = true },
        { name = "projected_camera_position_half_life", type = "number",             required = true },
        { name = "projected_camera_rotation_half_life", type = "number",             required = true },
        { name = "projected_camera_forward_offset",     type = "number",             required = true },
        { name = "ground_region_width",                 type = "number",             required = true },
        { name = "ground_region_height",                type = "number",             required = true },
        { name = "horizon",                             type = "number",             required = true },
        { name = "near_distance",                       type = "number",             required = true },
        { name = "far_distance",                        type = "number",             required = true },
        { name = "horizontal_fov",                      type = "number",             required = true }
      }
    }
  )
end

return ProjectRenderResourceTypes
