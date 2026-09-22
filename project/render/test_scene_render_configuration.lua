local TestSceneRenderConfiguration = {}
TestSceneRenderConfiguration.__index = TestSceneRenderConfiguration

-- Creates the data used to configure cameras and projected rendering for the test scene.
function TestSceneRenderConfiguration.new(options)
  options = options or {}

  local loop_visual_padding = options.loop_visual_padding or 1024
  assert(type(loop_visual_padding) == "number"
    and loop_visual_padding >= 0 and loop_visual_padding < math.huge,
    "loop visual padding must be finite and non-negative")

  -- All four coordinates are required together; omission keeps camera movement unrestricted.
  local world_bounds = {
    min_x = options.world_camera_min_x,
    min_y = options.world_camera_min_y,
    max_x = options.world_camera_max_x,
    max_y = options.world_camera_max_y
  }

  if next(world_bounds) == nil then
    world_bounds = nil
  else
    for _, name in ipairs({ "min_x", "min_y", "max_x", "max_y" }) do
      local value = world_bounds[name]
      assert(type(value) == "number" and value > -math.huge and value < math.huge,
        "world camera bounds require a finite " .. name)
    end

    assert(world_bounds.max_x >= world_bounds.min_x
      and world_bounds.max_y >= world_bounds.min_y,
      "world camera maximum bounds must not be below minimum bounds")
  end

  local world_elevation_component = options.world_camera_elevation_component

  assert(world_elevation_component == nil
    or type(world_elevation_component) == "string" and world_elevation_component ~= "",
    "world camera elevation component must be a non-empty name")

  local elevation_component = options.camera_elevation_component
  local elevation_half_life = options.camera_elevation_half_life or 0.08

  assert(elevation_component == nil
    or type(elevation_component) == "string" and elevation_component ~= "",
    "camera elevation component must be a non-empty name")
  assert(type(elevation_half_life) == "number"
    and elevation_half_life >= 0 and elevation_half_life < math.huge,
    "camera elevation half-life must be finite and non-negative")
  assert(type(options.world_camera_target_entity) == "string"
    and options.world_camera_target_entity ~= "",
    "test scene render configuration requires a world camera target entity")
  assert(type(options.projected_camera_target_entity) == "string"
    and options.projected_camera_target_entity ~= "",
    "test scene render configuration requires a projected camera target entity")
  assert(type(options.world_camera_position_half_life) == "number"
    and options.world_camera_position_half_life > 0,
    "test scene render configuration requires a positive world camera position half-life")
  assert(type(options.projected_camera_position_half_life) == "number"
    and options.projected_camera_position_half_life > 0,
    "test scene render configuration requires a positive projected camera position half-life")
  assert(type(options.projected_camera_rotation_half_life) == "number"
    and options.projected_camera_rotation_half_life > 0,
    "test scene render configuration requires a positive projected camera rotation half-life")
  assert(type(options.projected_camera_forward_offset) == "number",
    "test scene render configuration requires a numeric projected camera forward offset")
  assert(type(options.ground_region_width) == "number" and options.ground_region_width > 0,
    "test scene render configuration requires a positive ground region width")
  assert(type(options.ground_region_height) == "number" and options.ground_region_height > 0,
    "test scene render configuration requires a positive ground region height")
  assert(type(options.horizon) == "number" and options.horizon > 0 and options.horizon < 1,
    "test scene render configuration horizon must be between zero and one")
  assert(type(options.near_distance) == "number" and options.near_distance > 0,
    "test scene render configuration requires a positive near distance")
  assert(type(options.far_distance) == "number"
    and options.far_distance > options.near_distance,
    "test scene render configuration far distance must be greater than near distance")
  assert(type(options.horizontal_fov) == "number"
    and options.horizontal_fov > 0 and options.horizontal_fov < math.pi,
    "test scene render configuration horizontal FOV must be between zero and pi")
  assert(type(options.camera_elevation) == "number"
    and options.camera_elevation > -math.huge and options.camera_elevation < math.huge,
    "test scene render configuration requires a finite camera elevation")
  assert(type(options.reference_distance) == "number"
    and options.reference_distance > 0 and options.reference_distance < math.huge,
    "test scene render configuration requires a finite positive reference distance")
  assert(options.ground_levels ~= nil
    and type(options.ground_levels.get_elevation) == "function",
    "test scene render configuration requires ground levels exposing get_elevation")
  assert(options.render_mode == "perspective" or options.render_mode == "orthographic",
    "test scene render configuration requires a supported render mode")
  assert(type(options.orthographic_elevation_scale) == "number"
    and options.orthographic_elevation_scale >= 0
    and options.orthographic_elevation_scale < math.huge,
    "test scene render configuration requires a finite non-negative elevation scale")

  -- Resolve the fixed ground level once during configuration construction.
  local ground_elevation = options.ground_levels:get_elevation(options.ground_level)

  -- These values define which entities drive each camera and how they follow their targets.
  local camera = {
    world_target_entity = options.world_camera_target_entity,
    world_bounds = world_bounds,
    world_map_bounds = options.world_camera_map_bounds,
    world_elevation_component = world_elevation_component,
    projected_target_entity = options.projected_camera_target_entity,
    world_position_half_life = options.world_camera_position_half_life,
    projected_position_half_life = options.projected_camera_position_half_life,
    projected_rotation_half_life = options.projected_camera_rotation_half_life,
    projected_forward_offset = options.projected_camera_forward_offset
  }

  -- These values define the captured world region and its perspective projection.
  local projection = {
    region_width = options.ground_region_width,
    region_height = options.ground_region_height,
    horizon = options.horizon,
    near_distance = options.near_distance,
    far_distance = options.far_distance,
    horizontal_fov = options.horizontal_fov,
    camera_elevation = options.camera_elevation,
    camera_elevation_component = elevation_component,
    camera_elevation_half_life = elevation_half_life,
    reference_distance = options.reference_distance,
    ground_elevation = ground_elevation,
    render_mode = options.render_mode,
    loop_visual_padding = loop_visual_padding,
    orthographic_elevation_scale = options.orthographic_elevation_scale,
  }

  return setmetatable({
    camera = camera,
    projection = projection
  }, TestSceneRenderConfiguration)
end

-- Returns the entity id followed by the regular world camera.
function TestSceneRenderConfiguration:get_world_camera_target_entity()
  return self.camera.world_target_entity
end

-- Returns the entity id followed by the projected camera.
function TestSceneRenderConfiguration:get_projected_camera_target_entity()
  return self.camera.projected_target_entity
end

-- Returns the regular world camera position smoothing half-life.
function TestSceneRenderConfiguration:get_world_camera_position_half_life()
  return self.camera.world_position_half_life
end

-- Returns the projected camera position smoothing half-life.
function TestSceneRenderConfiguration:get_projected_camera_position_half_life()
  return self.camera.projected_position_half_life
end

-- Returns the projected camera rotation smoothing half-life.
function TestSceneRenderConfiguration:get_projected_camera_rotation_half_life()
  return self.camera.projected_rotation_half_life
end

-- Returns the oriented forward offset applied to the projected camera.
function TestSceneRenderConfiguration:get_projected_camera_forward_offset()
  return self.camera.projected_forward_offset
end

-- Returns the width of the captured projected-world region.
function TestSceneRenderConfiguration:get_ground_region_width()
  return self.projection.region_width
end

-- Returns the height of the captured projected-world region.
function TestSceneRenderConfiguration:get_ground_region_height()
  return self.projection.region_height
end

-- Returns the normalized screen-space horizon used by the projection.
function TestSceneRenderConfiguration:get_horizon()
  return self.projection.horizon
end

-- Returns the nearest visible projected-world distance.
function TestSceneRenderConfiguration:get_near_distance()
  return self.projection.near_distance
end

-- Returns the farthest visible projected-world distance.
function TestSceneRenderConfiguration:get_far_distance()
  return self.projection.far_distance
end

-- Returns the horizontal projection field of view in radians.
function TestSceneRenderConfiguration:get_horizontal_fov()
  return self.projection.horizontal_fov
end

-- Returns fixed camera elevation or the target-relative offset when tracking is enabled.
function TestSceneRenderConfiguration:get_camera_elevation()
  return self.projection.camera_elevation
end

-- Returns the depth at which billboards have unit scale.
function TestSceneRenderConfiguration:get_reference_distance()
  return self.projection.reference_distance
end

-- Returns the ground elevation resolved from the configured spatial level.
function TestSceneRenderConfiguration:get_ground_elevation()
  return self.projection.ground_elevation
end

-- Returns the presentation mode selected by this scene.
function TestSceneRenderConfiguration:get_render_mode()
  return self.projection.render_mode
end

-- Returns screen-vertical displacement per elevation unit before camera zoom.
function TestSceneRenderConfiguration:get_orthographic_elevation_scale()
  return self.projection.orthographic_elevation_scale
end

-- Returns the optional elevation component on the projected camera target.
function TestSceneRenderConfiguration:get_camera_elevation_component()
  return self.projection.camera_elevation_component
end

-- Returns vertical tracking smoothing, with zero selecting immediate following.
function TestSceneRenderConfiguration:get_camera_elevation_half_life()
  return self.projection.camera_elevation_half_life
end

-- Returns the optional elevation component followed by the orthographic camera.
function TestSceneRenderConfiguration:get_world_camera_elevation_component()
  return self.camera.world_elevation_component
end

--- Returns the optional fixed bounds used by the orthographic camera.
--- Coordinates describe the view area at Z = 0, not entity movement limits.
---@return CameraBounds|nil bounds Validated rectangle; nil means unrestricted tracking.
function TestSceneRenderConfiguration:get_world_camera_bounds()
  return self.camera.world_bounds
end

--- Returns the world-space margin used to select repeated visuals.
--- Must cover their extent from the anchor, including scale and local transforms.
---@return number padding Extra viewport margin in world units.
function TestSceneRenderConfiguration:get_loop_visual_padding()
  return self.projection.loop_visual_padding
end

--- Returns optional map framing, independent from the global fallback bounds.
---@return MapCameraBounds? configuration Shared map framing configuration.
function TestSceneRenderConfiguration:get_world_camera_map_bounds()
  return self.camera.world_map_bounds
end

return TestSceneRenderConfiguration
