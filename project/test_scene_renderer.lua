local love = require("love")

-- Camera components control the regular and projected viewpoints independently.
local Camera2D = require("engine.render.camera_2d")
local CameraPositionControl = require("engine.render.camera_position_control")
local AxisAlignedBoundsConstraint = require("engine.render.camera_position.axis_aligned_bounds_constraint")
local CameraElevationControl = require("engine.render.camera_elevation_control")
local EntityPositionPolicy = require("engine.render.camera_position.entity_position_policy")
local OrientedOffsetPositionPolicy = require("engine.render.camera_position.oriented_offset_position_policy")
local PositionResponse = require("engine.render.camera_position.position_response")
local CameraRotationControl = require("engine.render.camera_rotation_control")
local EntityRotationPolicy = require("engine.render.camera_rotation.entity_rotation_policy")
local RotationResponse = require("engine.render.camera_rotation.rotation_response")
local OrthographicProjection = require("engine.render.projections.orthographic_projection")

-- Render layers and views compose the different spaces drawn by the test scene.
local RenderLayer = require("engine.render.render_layer")
local RenderLayerStack = require("engine.render.render_layer_stack")
local RenderLayerGroup = require("engine.render.render_layer_group")
local LayerTransform2D = require("engine.render.layer_transform_2d")
local RenderViewStack = require("engine.render.render_view_stack")
local CanvasRenderView = require("engine.render.canvas_render_view")
local WorldRegionView = require("engine.render.world_region_view")
local PeriodicBillboardSource = require("engine.render.periodic_billboard_source")

-- Projected rendering converts the captured world region and entity visuals into perspective output.
local ProjectedWorldPlane = require("project.render.projections.projected_world_plane")
local ProjectedBillboardRenderer = require("engine.render.projected_billboard_renderer")
local BillboardSourceGroup = require("engine.render.billboard_source_group")
local PerspectiveProjection = require("engine.render.projections.perspective_projection")
local PeriodicQuery = require("engine.world.spatial.periodic_query")

-- Spatial debug rendering remains independent from the projected visual pipeline.
local SpatialDebugRenderer = require("engine.debug.spatial_debug_renderer")


---@class TestSceneRenderer: TestSceneRendererFields
local TestSceneRenderer = {}
TestSceneRenderer.__index = TestSceneRenderer

local width = love.graphics.getWidth()

-- Returns one required project entity with a useful error when the test definition is incomplete.
local function require_entity(project, id)
  local entity = project.entities_by_id[id]
  assert(entity ~= nil, "test scene renderer requires entity: " .. id)
  return entity
end

-- Resolves the entities required by the current test scene.
local function resolve_entities(self)
  -- These references are shared by rendering, camera tracking, and diagnostics.
  self.bounce_ball = require_entity(self.project, "bounce_ball")
  self.floor = require_entity(self.project, "floor")
  self.door = require_entity(self.project, "door")
  self.player = require_entity(self.project, "player")
  self.step_player = require_entity(self.project, "step_player")
  self.small_grid_area = require_entity(self.project, "small_grid_area")
  self.large_grid_area = require_entity(self.project, "large_grid_area")
  self.free_area = require_entity(self.project, "free_area")
end

--- Creates independent camera controls and optional bounds for the orthographic view.
--- Applies bounds during initialization, before the first frame is drawn.
---@param self TestSceneRenderer Renderer receiving the camera controls.
---@param elevation_source? table Live source exposing get_elevation.
local function create_cameras(self, elevation_source)
  local configuration = self.render_configuration
  local world_x, world_y = self.world_camera_target:get_position()
  local projected_x, projected_y = self.projected_camera_target:get_position()

  self.camera = Camera2D.new({ x = world_x, y = world_y })
  self.projected_camera = Camera2D.new({
    x = projected_x,
    y = projected_y,
    rotation = self.projected_camera_target:get_rotation()
  })

  self.projected_camera_rotation_response = RotationResponse.new({
    half_life = configuration:get_projected_camera_rotation_half_life()
  })

  self.projected_camera_rotation = CameraRotationControl.new(
    self.projected_camera,
    EntityRotationPolicy.new(self.projected_camera_target),
    { response = self.projected_camera_rotation_response }
  )

  self.projected_camera_offset = OrientedOffsetPositionPolicy.new(
    EntityPositionPolicy.new(self.projected_camera_target),
    function() return self.projected_camera:get_rotation() end,
    { forward = configuration:get_projected_camera_forward_offset() }
  )

  -- Start at the complete target, including the configured oriented offset.
  self.projected_camera:set_position(
    self.projected_camera_offset:resolve({ camera = self.projected_camera })
  )

  self.projected_camera_position = CameraPositionControl.new(
    self.projected_camera,
    self.projected_camera_offset,
    {
      topology = self.world_topology,
      response = PositionResponse.new({
        half_life = configuration:get_projected_camera_position_half_life()
      })
    }
  )

  -- The perspective debug view keeps its ordinary ground-space camera target.
  if configuration:get_render_mode() ~= "orthographic" then
    elevation_source = nil
  end

  local topology = nil
  if configuration:get_render_mode() == "orthographic" then
    topology = self.world_topology
  end

  local world_policy = EntityPositionPolicy.new(self.world_camera_target, {
    elevation_source = elevation_source,
    elevation_scale = configuration:get_orthographic_elevation_scale(),
    topology = topology
  })

  -- Start at the visual target to avoid sliding from ground level during loading.
  self.camera:set_position(world_policy:resolve({ camera = self.camera }))

  local constraints = {}
  local bounds = configuration:get_world_camera_bounds()

  if configuration:get_render_mode() == "orthographic" and bounds ~= nil then
    constraints[1] = AxisAlignedBoundsConstraint.new({
      min_x = bounds.min_x,
      min_y = bounds.min_y,
      max_x = bounds.max_x,
      max_y = bounds.max_y,
      constrain_x = topology == nil or not topology.loop_x,
      constrain_y = topology == nil or not topology.loop_y
    })
  end

  self.camera_position_response = PositionResponse.new({
    half_life = configuration:get_world_camera_position_half_life()
  })

  self.camera_position = CameraPositionControl.new(
    self.camera,
    world_policy,
    {
      response = self.camera_position_response,
      constraints = constraints
    }
  )

  -- A zero-time update applies constraints without advancing position smoothing.
  self.camera_position:update(0)
end

-- Creates the captured world region and the perspective projection used by the ground and billboards.
local function create_projected_world(self)
  local configuration = self.render_configuration

  -- This transform remains available for visual-only ground-space adjustments.
  self.ground_transform = LayerTransform2D.new()

  -- The capture dimensions are project data and no longer need to form a square.
  self.ground_region_width =
      configuration:get_ground_region_width()

  self.ground_region_height =
      configuration:get_ground_region_height()

  local projected_x, projected_y =
      self.projected_camera:get_position()

  local half_width = self.ground_region_width * 0.5
  local half_height = self.ground_region_height * 0.5

  -- This region moves with the projected camera while preserving configured dimensions.
  self.ground_world_region = WorldRegionView.new({
    min_x = projected_x - half_width,
    min_y = projected_y - half_height,
    max_x = projected_x + half_width,
    max_y = projected_y + half_height
  })

  -- Perspective calculations are shared by plane and billboard presentation.
  self.perspective_projection = PerspectiveProjection.new({
    viewpoint = self.projected_camera,
    horizon = configuration:get_horizon(),
    near_distance = configuration:get_near_distance(),
    far_distance = configuration:get_far_distance(),
    horizontal_fov = configuration:get_horizontal_fov(),
    camera_elevation = configuration:get_camera_elevation(),
    reference_distance = configuration:get_reference_distance(),
  })

  -- The ground presenter supplies only its captured region and presentation state.
  self.ground_plane = ProjectedWorldPlane.new({
    projection = self.perspective_projection,
    source_region = self.ground_world_region,
    elevation = configuration:get_ground_elevation()
  })

  self.billboard_renderer = ProjectedBillboardRenderer.new(self.perspective_projection)

  self.orthographic_projection = OrthographicProjection.new({
    camera = self.camera,
    elevation_scale = configuration:get_orthographic_elevation_scale()
  })

  self.orthographic_billboard_renderer =
      ProjectedBillboardRenderer.new(self.orthographic_projection)

  self.ground_canvas = CanvasRenderView.new({
    presenter = self.ground_plane
  })

  -- Ground-related layers share the same capture canvas and world region.
  self.projected_world = RenderLayerGroup.new({
    name = "projected_world",
    order = 100,
    view = RenderViewStack.new({
      self.ground_canvas,
      self.ground_world_region
    })
  })
end

-- Creates the ordered render layers used by the current test scene.
local function create_layers(self)
  self.layers = RenderLayerStack.new()

  local orthographic = self.render_configuration:get_render_mode() == "orthographic"
  self.projected_world:set_enabled(not orthographic)

  -- The physical floor becomes the base surface captured by the projected world.
  self.projected_world:add(RenderLayer.new({
    name = "ground",
    order = 100,
    view = self.ground_transform,
    draw = function()
      self:_draw_ground()
    end
  }))

  -- Development areas are captured in the same projected space as the ground.
  self.projected_world:add(RenderLayer.new({
    name = "ground_debug",
    order = 200,
    draw = function()
      self:_draw_ground_debug()
    end
  }))

  -- The whole projected ground group is submitted as one layer hierarchy.
  self.layers:add(self.projected_world)

  self.layers:add(RenderLayer.new({
    name = "orthographic_ground",
    order = 100,
    enabled = orthographic,
    view = self.camera,
    draw = function()
      self:_draw_orthographic_ground()
    end
  }))

  -- Projected vertical entities are rendered over the projected ground.
  self.layers:add(RenderLayer.new({
    name = "projected_billboards",
    order = 150,
    draw = function()
      self:_draw_projected_billboards()
    end
  }))

  -- This layer preserves the ordinary non-projected debug world.
  self.layers:add(RenderLayer.new({
    name = "world",
    order = 200,
    view = self.camera,
    draw = function()
      self:_draw_world()
    end
  }))

  -- Runtime information is drawn directly in screen coordinates.
  self.layers:add(RenderLayer.new({
    name = "screen",
    order = 1000,
    draw = function()
      self:_draw_diagnostics()
    end
  }))

  self.layers:add(RenderLayer.new({
    name = "player_coordinates",
    order = 1100,
    draw = function()
      self:_draw_player_coordinates()
    end
  }))

  self.layers:add(RenderLayer.new({
    name = "door_coordinates",
    order = 1200,
    draw = function()
      self:_draw_door_coordinates()
    end
  }))
end

-- Creates the billboard composition from the sources prepared for this test scene.
local function create_billboards(self, options)
  -- This source contains project-configured animated entity representations.
  local projected_character_billboard_source =
      options.projected_character_billboard_source

  assert(projected_character_billboard_source ~= nil
    and type(projected_character_billboard_source.append_entries) == "function",
    "test scene renderer requires a projected character billboard source")

  -- This source owns the temporary procedural bouncing-ball visual.
  local bounce_ball_billboard_source =
      options.bounce_ball_billboard_source

  assert(bounce_ball_billboard_source ~= nil
    and type(bounce_ball_billboard_source.append_entries) == "function",
    "test scene renderer requires a bounce ball billboard source")
  assert(type(bounce_ball_billboard_source.update) == "function",
    "test scene renderer bounce ball billboard source must expose update")

  -- This source owns temporary projected visuals used only for scene inspection.
  local projected_debug_billboard_source =
      options.projected_debug_billboard_source

  assert(projected_debug_billboard_source ~= nil
    and type(projected_debug_billboard_source.append_entries) == "function",
    "test scene renderer requires a projected debug billboard source")

  -- This reference remains because the ball source still has renderer-owned playback timing.
  self.bounce_ball_billboard_source =
      bounce_ball_billboard_source



  -- This source temporarily proves the static declarative entity representation path.
  local static_test_billboard_source =
      options.static_test_billboard_source

  assert(static_test_billboard_source ~= nil
    and type(static_test_billboard_source.append_entries) == "function",
    "test scene renderer requires a static test billboard source")



  -- This group merges every billboard origin before one global projection and depth sort.
  self.projected_billboards = BillboardSourceGroup.new()

  -- Declarative animated entities contribute through their runtime-backed source.
  self.projected_billboards:add_source(projected_character_billboard_source)

  -- The procedural ball contributes independently from declarative character visuals.
  self.projected_billboards:add_source(bounce_ball_billboard_source)

  -- Project-specific inspection visuals contribute without adding drawing details to the renderer.
  self.projected_billboards:add_source(projected_debug_billboard_source)




  -- The static test representation shares the same billboard composition and global depth sorting.
  self.projected_billboards:add_source(static_test_billboard_source)
end

--- Creates the renderer used by the current Actrune test project.-- Creates the renderer used by the current Actrune test project.
function TestSceneRenderer.new(options)
  options = options or {}

  local self = setmetatable({}, TestSceneRenderer)

  -- Project data remains available because this renderer still represents a concrete test scene.
  self.project = options.project
  self.messages = options.messages or {}
  self.player_elevation = options.player_elevation
  self.world_topology = options.world_topology

  assert(self.player_elevation ~= nil
    and type(self.player_elevation.get_elevation) == "function",
    "test scene renderer requires a player elevation source")

  assert(self.project ~= nil, "test scene renderer requires a project")

  -- This provider exposes one event diagnostic without exposing the complete event runtime.
  self.active_event_count_provider =
      options.active_event_count_provider

  assert(type(self.active_event_count_provider) == "function",
    "test scene renderer requires an active event count provider")

  -- These narrow dependencies expose only the physics information used by diagnostics.
  self.physics_backend = options.physics_backend
  self.physics_step = options.physics_step

  -- This configuration supplies project-defined camera and projection parameters.
  self.render_configuration =
      options.render_configuration

  assert(self.render_configuration ~= nil,
    "test scene renderer requires a render configuration")
  assert(type(self.render_configuration.get_world_camera_position_half_life) == "function",
    "test scene renderer render configuration must expose camera settings")
  assert(type(self.render_configuration.get_ground_region_width) == "function",
    "test scene renderer render configuration must expose projection settings")
  assert(self.physics_backend ~= nil,
    "test scene renderer requires a physics backend")
  assert(type(self.physics_backend.get_linear_velocity) == "function",
    "test scene renderer physics backend must expose get_linear_velocity")
  assert(type(self.physics_backend.get_angular_velocity) == "function",
    "test scene renderer physics backend must expose get_angular_velocity")
  assert(self.physics_step ~= nil,
    "test scene renderer requires a physics fixed step")

  -- These entities drive camera tracking independently from the renderer's other scene entities.
  self.world_camera_target =
      options.world_camera_target

  self.projected_camera_target =
      options.projected_camera_target

  assert(self.world_camera_target ~= nil
    and type(self.world_camera_target.get_position) == "function",
    "test scene renderer requires a world camera target exposing get_position")

  assert(self.projected_camera_target ~= nil
    and type(self.projected_camera_target.get_position) == "function"
    and type(self.projected_camera_target.get_rotation) == "function",
    "test scene renderer requires a projected camera target exposing get_position and get_rotation")

  -- Each construction step owns one clearly separated part of the renderer setup.
  resolve_entities(self)
  create_cameras(self, options.world_camera_elevation_source)
  create_projected_world(self)
  if options.projected_camera_elevation_source ~= nil then
    self.projected_camera_elevation = CameraElevationControl.new(
      self.perspective_projection,
      options.projected_camera_elevation_source,
      {
        offset = self.render_configuration:get_camera_elevation(),
        half_life = self.render_configuration:get_camera_elevation_half_life()
      }
    )
  end
  create_layers(self)
  create_billboards(self, options)

  local topology = self.world_topology

  if topology ~= nil and (topology.loop_x or topology.loop_y) then
    local orthographic = self.render_configuration:get_render_mode() == "orthographic"

    ---@type PeriodicBillboardSourceOptions
    local repetition_options = {
      padding = self.render_configuration:get_loop_visual_padding(),
      elevation_scale = orthographic
          and self.render_configuration:get_orthographic_elevation_scale() or 0
    }

    if not orthographic then
      repetition_options.bounds_provider = function(padding)
        return self.perspective_projection:get_view_bounds(padding)
      end
    end

    self.periodic_billboards = PeriodicBillboardSource.new(
      self.projected_billboards, topology,
      orthographic and self.camera or self.projected_camera,
      repetition_options
    )
  end

  return self
end

-- Draws shared billboard entries through the presentation selected by this scene.
function TestSceneRenderer:_draw_projected_billboards()
  local source = self.periodic_billboards or self.projected_billboards
  local entries = source:get_entries()

  if self.render_configuration:get_render_mode() == "orthographic" then
    local viewport_x, viewport_y, viewport_width, viewport_height =
        self.camera:get_viewport()
    local output_width, output_height = love.graphics.getDimensions()

    love.graphics.push("all")
    love.graphics.setScissor(viewport_x, viewport_y, viewport_width, viewport_height)

    self.orthographic_billboard_renderer:draw(
      entries,
      output_width,
      output_height,
      { renderer = self }
    )

    love.graphics.pop()
    return
  end

  local canvas = self.ground_canvas:get_canvas()
  local output_width, output_height = canvas:getDimensions()

  self.billboard_renderer:draw(
    entries,
    output_width,
    output_height,
    { renderer = self }
  )
end

-- Draws the current runtime diagnostic information in screen space.
function TestSceneRenderer:_draw_diagnostics()
  love.graphics.printf(table.concat(self.messages, "\n"), -20, 20, width, "right")

  -- The provider keeps event runtime details outside the rendering layer.
  local active_event_count = self.active_event_count_provider()
  love.graphics.printf("Active events: " .. active_event_count, -20, 20, width, "right")

  -- These values expose the current physics state of the bouncing-ball test.
  local velocity_x, velocity_y = self.physics_backend:get_linear_velocity(self.bounce_ball)

  local angular_velocity = self.physics_backend:get_angular_velocity(self.bounce_ball)

  love.graphics.printf(string.format("Ball velocity: %.2f, %.2f", velocity_x, velocity_y), -20, 50, width, "right")
  love.graphics.printf(string.format("Angular velocity: %.4f", angular_velocity), -20, 70, width, "right")
  love.graphics.printf("FPS: " .. love.timer.getFPS(), -20, 100, width, "right")

  -- The fixed-step diagnostics show how many physics simulation steps ran in the last frame.
  love.graphics.printf("Fixed steps: " .. self.physics_step.last_steps, -20, 120, width, "right")

  love.graphics.printf("WASD: continuous | Arrows: contextual grid/free movement", -20, 140, width, "right")
end

-- Draws the current physics test objects.
function TestSceneRenderer:_draw_physics()
  SpatialDebugRenderer.draw_shape(self.bounce_ball, "physics")
  SpatialDebugRenderer.draw_shape(self.floor, "physics")
  SpatialDebugRenderer.draw_circle_rotation(self.bounce_ball, "physics")
end

-- Draws the ground through the regular camera at its configured elevation.
function TestSceneRenderer:_draw_orthographic_ground()
  local configuration = self.render_configuration
  local offset = configuration:get_ground_elevation()
      * configuration:get_orthographic_elevation_scale()
  local rotation = self.camera:get_rotation()

  -- Convert screen-up displacement into world axes before the camera transform.
  love.graphics.translate(
    math.sin(rotation) * offset,
    -math.cos(rotation) * offset
  )

  self.ground_transform:begin()
  self:_draw_ground()
  self.ground_transform:finish()

  self:_draw_ground_debug()
end

--- Draws ground outlines through the current layer transform.
function TestSceneRenderer:_draw_ground()
  self:_draw_shape(self.floor, "physics")
end

--- Draws the planar collision outline of the static test entity.
function TestSceneRenderer:_draw_world()
  self:_draw_shape(self.step_player, "collision")
end

--- Displays map location, declared content count and the player's global XYZ.
function TestSceneRenderer:_draw_player_coordinates()
  local x, y = self.player:get_position()
  local z = self.player_elevation:get_elevation()
  local layouts = self.project.resources.map_layout

  ---@type MapLayout?
  local layout = layouts and layouts:get("main")
  local map = layout and layout:find_map(x, y)
  local map_id = map and map.id or "--"
  local content_count = map and #map.entities or 0

  love.graphics.printf(
    string.format("Player | Map: %s | Content: %d | X: %.2f | Y: %.2f | Z: %.2f",
      map_id, content_count, x, y, z),
    -20, 180, width, "right"
  )
end

-- Draws the door's current world coordinates in screen space.
function TestSceneRenderer:_draw_door_coordinates()
  local door_x, door_y = self.door:get_position()

  love.graphics.printf(string.format("Door position: | X: %.2f | Y: %.2f ", door_x, door_y), -20, 200, width,
    "right")
end

--- Draws development areas in the active ground view.
function TestSceneRenderer:_draw_ground_debug()
  self:_draw_shape(self.small_grid_area, "area")
  self:_draw_shape(self.large_grid_area, "area")
  self:_draw_shape(self.free_area, "area")
end

-- Draws all configured render layers in their current order.
function TestSceneRenderer:draw()
  -- The layer stack owns ordering and applies each configured view before drawing.
  self.layers:draw({
    renderer = self
  })
end

--- Draws periodic outlines inside the active world-space view.
--- Uses the full active canvas during capture, or the camera viewport on screen.
--- Call after applying the world view and any elevation or layer transforms.
--- Requires an invertible graphics transform.
---@param entity? Entity Logical shape owner.
---@param shape_name string Name of the shape to draw.
function TestSceneRenderer:_draw_shape(entity, shape_name)
  if entity == nil or not entity:is_active() then return end
  local topology = self.world_topology

  if topology == nil or not (topology.loop_x or topology.loop_y) then
    SpatialDebugRenderer.draw_shape(entity, shape_name)
    return
  end

  local shape = entity:get_shape(shape_name)
  if shape == nil then return end

  local vx, vy, width, height
  local canvas = love.graphics.getCanvas()

  if canvas ~= nil then
    vx, vy = 0, 0
    width, height = canvas:getDimensions()
  else
    vx, vy, width, height = self.camera:get_viewport()
  end

  local x1, y1 = love.graphics.inverseTransformPoint(vx, vy)
  local x2, y2 = love.graphics.inverseTransformPoint(vx + width, vy)
  local x3, y3 = love.graphics.inverseTransformPoint(vx + width, vy + height)
  local x4, y4 = love.graphics.inverseTransformPoint(vx, vy + height)

  local bounds = {
    min_x = math.min(x1, x2, x3, x4),
    min_y = math.min(y1, y2, y3, y4),
    max_x = math.max(x1, x2, x3, x4),
    max_y = math.max(y1, y2, y3, y4)
  }

  PeriodicQuery.visit_transforms(topology, bounds, shape, entity.transform,
    function(transform)
      SpatialDebugRenderer.draw_shape(entity, shape_name, transform)
    end)
end

-- Updates camera tracking and the captured projected world region.
function TestSceneRenderer:update(dt)
  self.camera_position:update(dt)

  -- Resolve rotation before the position offset that depends on it.
  self.projected_camera_rotation:update(dt)
  self.projected_camera_position:update(dt)

  if self.projected_camera_elevation ~= nil then
    self.projected_camera_elevation:update(dt)
  end

  local projected_x, projected_y = self.projected_camera:get_position()
  local half_width = self.ground_region_width * 0.5
  local half_height = self.ground_region_height * 0.5

  -- Preserve capture dimensions while following the horizontal viewpoint.
  self.ground_world_region:set_bounds(
    projected_x - half_width,
    projected_y - half_height,
    projected_x + half_width,
    projected_y + half_height
  )

  self.bounce_ball_billboard_source:update(dt)
end

return TestSceneRenderer
