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
        {
          name = "world_camera_position_half_life",
          type = "number",
          required = true
        },
        {
          name = "projected_camera_position_half_life",
          type = "number",
          required = true
        },
        {
          name = "projected_camera_rotation_half_life",
          type = "number",
          required = true
        },
        {
          name = "projected_camera_forward_offset",
          type = "number",
          required = true
        },
        {
          name = "ground_region_width",
          type = "number",
          required = true
        },
        {
          name = "ground_region_height",
          type = "number",
          required = true
        },
        {
          name = "horizon",
          type = "number",
          required = true
        },
        {
          name = "near_distance",
          type = "number",
          required = true
        },
        {
          name = "far_distance",
          type = "number",
          required = true
        },
        {
          name = "horizontal_fov",
          type = "number",
          required = true
        }
      }
    }
  )
end

return ProjectRenderResourceTypes
