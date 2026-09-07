local TestSceneRenderConfiguration = {}
TestSceneRenderConfiguration.__index = TestSceneRenderConfiguration

-- Creates the data used to configure cameras and projected rendering for the test scene.
function TestSceneRenderConfiguration.new(options)
  options = options or {}

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

  -- Resolve the fixed ground level once during configuration construction.
  local ground_elevation = options.ground_levels:get_elevation(options.ground_level)

  -- These values define which entities drive each camera and how they follow their targets.
  local camera = {
    world_target_entity = options.world_camera_target_entity,
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
    reference_distance = options.reference_distance,
    ground_elevation = ground_elevation,
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

-- Returns the absolute elevation of the projected camera.
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

return TestSceneRenderConfiguration
