local love = require("love")

-- Camera components control the regular and projected viewpoints independently.
local Camera2D = require("engine.render.camera_2d")
local CameraPositionControl = require("engine.render.camera_position_control")
local EntityPositionPolicy = require("engine.render.camera_position.entity_position_policy")
local OrientedOffsetPositionPolicy = require("engine.render.camera_position.oriented_offset_position_policy")
local PositionResponse = require("engine.render.camera_position.position_response")
local CameraRotationControl = require("engine.render.camera_rotation_control")
local EntityRotationPolicy = require("engine.render.camera_rotation.entity_rotation_policy")
local RotationResponse = require("engine.render.camera_rotation.rotation_response")

-- Render layers and views compose the different spaces drawn by the test scene.
local RenderLayer = require("engine.render.render_layer")
local RenderLayerStack = require("engine.render.render_layer_stack")
local RenderLayerGroup = require("engine.render.render_layer_group")
local LayerTransform2D = require("engine.render.layer_transform_2d")
local RenderViewStack = require("engine.render.render_view_stack")
local CanvasRenderView = require("engine.render.canvas_render_view")
local WorldRegionView = require("engine.render.world_region_view")

-- Projected rendering converts the captured world region and entity visuals into perspective output.
local ProjectedWorldPlane = require("project.render.projections.projected_world_plane")
local ProjectedBillboardRenderer = require("engine.render.projected_billboard_renderer")
local BillboardSourceGroup = require("engine.render.billboard_source_group")

-- Spatial debug rendering remains independent from the projected visual pipeline.
local SpatialDebugRenderer = require("engine.debug.spatial_debug_renderer")

local TestSceneRenderer = {}
TestSceneRenderer.__index = TestSceneRenderer

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

-- Creates the regular and projected cameras together with their follow controls.
local function create_cameras(self)
  local player_x, player_y = self.player:get_position()

  -- This camera renders the ordinary top-down/debug world view.
  self.camera = Camera2D.new({
    x = player_x,
    y = player_y
  })

  -- This camera provides the viewpoint used by the perspective projection.
  self.projected_camera = Camera2D.new({
    x = player_x,
    y = player_y,
    rotation = self.player:get_rotation()
  })

  -- Rotation smoothing keeps projected turns independent from player rotation snapping.
  self.projected_camera_rotation_response = RotationResponse.new({
    half_life = 0.1
  })

  self.projected_camera_rotation = CameraRotationControl.new(
    self.projected_camera,
    EntityRotationPolicy.new(self.player),
    {
      response = self.projected_camera_rotation_response
    }
  )

  -- This policy places the projected viewpoint behind the player in its current orientation.
  self.projected_camera_offset = OrientedOffsetPositionPolicy.new(
    EntityPositionPolicy.new(self.player),
    function()
      return self.projected_camera:get_rotation()
    end,
    {
      forward = -96
    }
  )

  -- Position smoothing runs separately because the offset depends on the smoothed camera rotation.
  self.projected_camera_position = CameraPositionControl.new(
    self.projected_camera,
    self.projected_camera_offset,
    {
      response = PositionResponse.new({
        half_life = 0.08
      })
    }
  )

  -- The regular debug camera follows the player without the projected camera offset.
  self.camera_position_response = PositionResponse.new({
    half_life = 0.08
  })

  self.camera_position = CameraPositionControl.new(
    self.camera,
    EntityPositionPolicy.new(self.player),
    {
      response = self.camera_position_response
    }
  )
end

-- Creates the captured world region and the perspective projection used by the ground and billboards.
local function create_projected_world(self)
  -- These objects define the world area captured before perspective projection.
  self.ground_transform = LayerTransform2D.new()
  self.ground_region_size = 2048

  local projected_x, projected_y = self.projected_camera:get_position()
  local half_region = self.ground_region_size * 0.5

  -- This region moves with the projected camera while preserving a fixed capture size.
  self.ground_world_region = WorldRegionView.new({
    min_x = projected_x - half_region,
    min_y = projected_y - half_region,
    max_x = projected_x + half_region,
    max_y = projected_y + half_region
  })

  -- This projection converts world positions into the perspective-like projected space.
  self.ground_projection = ProjectedWorldPlane.new({
    viewpoint = self.projected_camera,
    source_region = self.ground_world_region,
    horizon = 0.3,
    near_distance = 32,
    far_distance = 800,
    horizontal_fov = math.rad(75)
  })

  -- Ground and billboards share the same projection so their perspective stays aligned.
  self.billboard_renderer = ProjectedBillboardRenderer.new(self.ground_projection)

  -- The world surface is first captured into this canvas before being projected.
  self.ground_canvas = CanvasRenderView.new({
    presenter = self.ground_projection
  })

  -- This group lets multiple ground-space layers share the same capture and world region.
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

  -- This group merges every billboard origin before one global projection and depth sort.
  self.projected_billboards = BillboardSourceGroup.new()

  -- Declarative animated entities contribute through their runtime-backed source.
  self.projected_billboards:add_source(projected_character_billboard_source)

  -- The procedural ball contributes independently from declarative character visuals.
  self.projected_billboards:add_source(bounce_ball_billboard_source)

  -- Project-specific inspection visuals contribute without adding drawing details to the renderer.
  self.projected_billboards:add_source(projected_debug_billboard_source)
end

-- Creates the renderer used by the current Actrune test project.-- Creates the renderer used by the current Actrune test project.
function TestSceneRenderer.new(options)
  options = options or {}

  local self = setmetatable({}, TestSceneRenderer)

  -- Project data remains available because this renderer still represents a concrete test scene.
  self.project = options.project
  self.messages = options.messages or {}

  assert(self.project ~= nil, "test scene renderer requires a project")

  -- This provider exposes one event diagnostic without exposing the complete event runtime.
  self.active_event_count_provider =
      options.active_event_count_provider

  assert(type(self.active_event_count_provider) == "function",
    "test scene renderer requires an active event count provider")

  -- These narrow dependencies expose only the physics information used by diagnostics.
  self.physics_backend = options.physics_backend
  self.physics_step = options.physics_step

  assert(self.physics_backend ~= nil,
    "test scene renderer requires a physics backend")
  assert(type(self.physics_backend.get_linear_velocity) == "function",
    "test scene renderer physics backend must expose get_linear_velocity")
  assert(type(self.physics_backend.get_angular_velocity) == "function",
    "test scene renderer physics backend must expose get_angular_velocity")
  assert(self.physics_step ~= nil,
    "test scene renderer requires a physics fixed step")

  -- Each construction step owns one clearly separated part of the renderer setup.
  resolve_entities(self)
  create_cameras(self)
  create_projected_world(self)
  create_layers(self)
  create_billboards(self, options)

  return self
end

-- Draws vertical world entities through the current perspective projection.
function TestSceneRenderer:_draw_projected_billboards()
  -- Billboard output uses the same dimensions as the canvas containing the projected ground.
  local canvas = self.ground_canvas:get_canvas()
  local width, height = canvas:getDimensions()

  -- All billboard sources are merged before projection so depth sorting remains global.
  self.billboard_renderer:draw(
    self.projected_billboards:get_entries(),
    width,
    height,
    {
      renderer = self
    }
  )
end

-- Draws the current runtime diagnostic information in screen space.
function TestSceneRenderer:_draw_diagnostics()
  love.graphics.print(table.concat(self.messages, "\n"), 20, 20)

  -- The provider keeps event runtime details outside the rendering layer.
  local active_event_count = self.active_event_count_provider()
  love.graphics.print("Active events: " .. active_event_count, 20, 100)

  -- These values expose the current physics state of the bouncing-ball test.
  local velocity_x, velocity_y =
      self.physics_backend:get_linear_velocity(self.bounce_ball)

  local angular_velocity =
      self.physics_backend:get_angular_velocity(self.bounce_ball)

  love.graphics.print(string.format("Ball velocity: %.2f, %.2f", velocity_x, velocity_y), 20, 130)
  love.graphics.print(string.format("Angular velocity: %.4f", angular_velocity), 20, 150)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 20, 180)

  -- The fixed-step diagnostics show how many physics simulation steps ran in the last frame.
  love.graphics.print("Fixed steps: " .. self.physics_step.last_steps, 20, 200)

  love.graphics.print("WASD: continuous | Arrows: contextual grid/free movement", 20, 220)
end

-- Draws the current physics test objects.
function TestSceneRenderer:_draw_physics()
  SpatialDebugRenderer.draw_shape(self.bounce_ball, "physics")
  SpatialDebugRenderer.draw_shape(self.floor, "physics")
  SpatialDebugRenderer.draw_circle_rotation(self.bounce_ball, "physics")
end

-- Draws world surfaces that conceptually belong below regular entities.
function TestSceneRenderer:_draw_ground()
  SpatialDebugRenderer.draw_shape(self.floor, "physics")
end

-- Draws regular world entities that are not currently part of the projected billboard space.
function TestSceneRenderer:_draw_world()
  SpatialDebugRenderer.draw_shape(self.step_player, "collision")
end

-- Draws the player's current world coordinates in screen space.
function TestSceneRenderer:_draw_player_coordinates()
  local player_x, player_y = self.player:get_position()
  love.graphics.print(string.format("Player position: %.2f, %.2f", player_x, player_y), 20, 250)
end

-- Draws the door's current world coordinates in screen space.
function TestSceneRenderer:_draw_door_coordinates()
  local door_x, door_y = self.door:get_position()
  love.graphics.print(string.format("Door position: %.2f, %.2f", door_x, door_y), 20, 270)
end

-- Draws development overlays that share the projected world plane.
function TestSceneRenderer:_draw_ground_debug()
  SpatialDebugRenderer.draw_shape(self.small_grid_area, "area")
  SpatialDebugRenderer.draw_shape(self.large_grid_area, "area")
  SpatialDebugRenderer.draw_shape(self.free_area, "area")
end

-- Updates time-dependent rendering behavior and the captured projected world region.
function TestSceneRenderer:update(dt)
  -- The regular camera follows the player independently from projected rendering.
  self.camera_position:update(dt)

  -- Rotation is updated first because the projected position offset depends on camera orientation.
  self.projected_camera_rotation:update(dt)
  self.projected_camera_position:update(dt)

  local projected_x, projected_y = self.projected_camera:get_position()
  local half_region = self.ground_region_size * 0.5

  -- The captured world region follows the projected camera while keeping a fixed size.
  self.ground_world_region:set_bounds(
    projected_x - half_region,
    projected_y - half_region,
    projected_x + half_region,
    projected_y + half_region
  )

  -- The temporary ball source still owns render-specific playback and advances once per render update.
  self.bounce_ball_billboard_source:update(dt)
end

-- Draws all configured render layers in their current order.
function TestSceneRenderer:draw()
  -- The layer stack owns ordering and applies each configured view before drawing.
  self.layers:draw({
    renderer = self
  })
end

return TestSceneRenderer
