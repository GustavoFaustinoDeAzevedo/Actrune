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
local BillboardVisual = require("engine.render.billboard_visual")
local IndexedBillboardVisual = require("engine.render.indexed_billboard_visual")
local BillboardSourceGroup = require("engine.render.billboard_source_group")

-- Animation playback is still used directly by the temporary bouncing-ball visual test.
local AnimationPlayer = require("engine.core.animation.animation_player")

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

-- Creates the renderer used by the current Actrune test project.
function TestSceneRenderer.new(options)
  options = options or {}

  local self = setmetatable({}, TestSceneRenderer)

  -- These objects provide project data, event diagnostics, and runtime systems used by this test renderer.
  self.project = options.project
  self.runtime = options.runtime
  self.messages = options.messages or {}

  assert(self.project ~= nil, "test scene renderer requires a project")
  assert(self.runtime ~= nil, "test scene renderer requires a runtime")
  assert(options.project_runtime ~= nil, "test scene renderer requires a project runtime")

  -- Physics is currently queried directly because diagnostics still inspect Box2D state.
  local physics_system = options.project_runtime:get_system("physics")
  assert(physics_system ~= nil, "test scene renderer requires the physics runtime system")

  -- These references are only used for physics diagnostics and fixed-step information.
  self.box2d = physics_system:get_backend()
  self.physics_step = physics_system:get_fixed_step()

  -- These entities are required by the current visual and diagnostic test scene.
  self.bounce_ball = require_entity(self.project, "bounce_ball")
  self.floor = require_entity(self.project, "floor")
  self.door = require_entity(self.project, "door")
  self.player = require_entity(self.project, "player")
  self.step_player = require_entity(self.project, "step_player")
  self.small_grid_area = require_entity(self.project, "small_grid_area")
  self.large_grid_area = require_entity(self.project, "large_grid_area")
  self.free_area = require_entity(self.project, "free_area")

  -- This clip drives the remaining manual billboard animation test.
  local ball_pulse_clip = self.project.resources.animation_clip:get("ball_pulse")

  local player_x, player_y = self.player:get_position()

  -- This camera renders the ordinary top-down/debug world view.
  self.camera = Camera2D.new({
    x = player_x,
    y = player_y
  })

  -- This camera acts as the viewpoint used by the projected world plane.
  self.projected_camera = Camera2D.new({
    x = player_x,
    y = player_y,
    rotation = self.player:get_rotation()
  })

  -- Rotation smoothing prevents projected viewpoint turns from snapping instantly.
  self.projected_camera_rotation_response = RotationResponse.new({
    half_life = 0.1
  })

  -- The projected camera follows the player's world rotation through an independent response.
  self.projected_camera_rotation = CameraRotationControl.new(
    self.projected_camera,
    EntityRotationPolicy.new(self.player),
    {
      response = self.projected_camera_rotation_response
    }
  )

  -- This policy keeps the projected viewpoint behind the player using the camera's current orientation.
  self.projected_camera_offset = OrientedOffsetPositionPolicy.new(
    EntityPositionPolicy.new(self.player),
    function()
      return self.projected_camera:get_rotation()
    end,
    {
      forward = -96
    }
  )

  -- Position smoothing lets the projected camera converge independently from its rotation.
  self.projected_camera_position = CameraPositionControl.new(
    self.projected_camera,
    self.projected_camera_offset,
    {
      response = PositionResponse.new({
        half_life = 0.08
      })
    }
  )

  -- This response smooths the regular world camera while it follows the player.
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

  -- These objects define the world region captured before perspective projection.
  self.ground_transform = LayerTransform2D.new()
  self.layers = RenderLayerStack.new()
  self.ground_region_size = 2048

  local projected_x, projected_y = self.projected_camera:get_position()
  local half_region = self.ground_region_size * 0.5

  -- This region follows the projected camera and limits what is captured into the projection canvas.
  self.ground_world_region = WorldRegionView.new({
    min_x = projected_x - half_region,
    min_y = projected_y - half_region,
    max_x = projected_x + half_region,
    max_y = projected_y + half_region
  })

  -- This projection converts captured world coordinates into the perspective-like screen space.
  self.ground_projection = ProjectedWorldPlane.new({
    viewpoint = self.projected_camera,
    source_region = self.ground_world_region,
    horizon = 0.3,
    near_distance = 32,
    far_distance = 800,
    horizontal_fov = math.rad(75)
  })

  -- Billboards use the same projection as the ground so both spaces remain visually aligned.
  self.billboard_renderer = ProjectedBillboardRenderer.new(self.ground_projection)

  -- The ground is first rendered to a canvas and then presented through the world projection.
  self.ground_canvas = CanvasRenderView.new({
    presenter = self.ground_projection
  })

  -- This group captures ground-related layers through the same view stack before presentation.
  self.projected_world = RenderLayerGroup.new({
    name = "projected_world",
    order = 100,
    view = RenderViewStack.new({
      self.ground_canvas,
      self.ground_world_region
    })
  })

  -- The physical floor becomes the base surface of the projected world.
  self.projected_world:add(RenderLayer.new({
    name = "ground",
    order = 100,
    view = self.ground_transform,
    draw = function()
      self:_draw_ground()
    end
  }))

  -- Area overlays share the captured projected-world space for development inspection.
  self.projected_world:add(RenderLayer.new({
    name = "ground_debug",
    order = 200,
    draw = function()
      self:_draw_ground_debug()
    end
  }))

  -- The projected-world group is presented before the projected billboard layer.
  self.layers:add(self.projected_world)

  -- Vertical projected entities are drawn after the projected ground.
  self.layers:add(RenderLayer.new({
    name = "projected_billboards",
    order = 150,
    draw = function()
      self:_draw_projected_billboards()
    end
  }))

  -- This layer keeps the ordinary world/debug view available beside the projected pipeline.
  self.layers:add(RenderLayer.new({
    name = "world",
    order = 200,
    view = self.camera,
    draw = function()
      self:_draw_world()
    end
  }))

  -- Runtime diagnostics are rendered directly in screen space.
  self.layers:add(RenderLayer.new({
    name = "screen",
    order = 1000,
    draw = function()
      self:_draw_diagnostics()
    end
  }))

  -- Player coordinates remain visible independently from world camera transforms.
  self.layers:add(RenderLayer.new({
    name = "player_coordinates",
    order = 1100,
    draw = function()
      self:_draw_player_coordinates()
    end
  }))

  -- Door coordinates help compare the projected representation with its world position.
  self.layers:add(RenderLayer.new({
    name = "door_coordinates",
    order = 1200,
    draw = function()
      self:_draw_door_coordinates()
    end
  }))

  -- These three temporary visuals expose different frames for the manual ball animation test.
  local ball_frame_a = BillboardVisual.new({
    width = 20,
    height = 20,
    draw = function(width, height)
      love.graphics.setColor(1, 1, 1, 0.7)
      love.graphics.circle("fill", width * 0.5, height * 0.5, 50)
    end
  })

  local ball_frame_b = BillboardVisual.new({
    width = 20,
    height = 20,
    draw = function(width, height)
      love.graphics.setColor(1, 1, 1, 0.8)
      love.graphics.circle("fill", width * 0.5, height * 0.5, 60)
    end
  })

  local ball_frame_c = BillboardVisual.new({
    width = 20,
    height = 20,
    draw = function(width, height)
      love.graphics.setColor(1, 1, 1, 0.9)
      love.graphics.circle("fill", width * 0.5, height * 0.5, 55)
    end
  })

  -- This AnimationPlayer owns only the playback state of the temporary ball visual.
  self.ball_animation = AnimationPlayer.new(ball_pulse_clip)

  -- The indexed visual selects its current frame without owning animation timing itself.
  local ball_animation_visual = IndexedBillboardVisual.new({
    visuals = {
      ball_frame_a,
      ball_frame_b,
      ball_frame_c,
      ball_frame_b
    },
    index_provider = function()
      return self.ball_animation:get_frame_index()
    end
  })

  -- This source contains the project-configured animated character billboards.
  local projected_character_billboard_source = options.projected_character_billboard_source

  assert(projected_character_billboard_source ~= nil
    and type(projected_character_billboard_source.append_entries) == "function",
    "test scene renderer requires a projected character billboard source")

  -- This group combines project-driven billboard sources with temporary test entries.
  self.projected_billboards = BillboardSourceGroup.new()

  -- Project-configured animated characters contribute their billboards through this source.
  self.projected_billboards:add_source(projected_character_billboard_source)

  -- This marker provides a simple projected reference for the floor entity position.
  self.projected_billboards:add_entry({
    id = "floor_marker",
    position_provider = function()
      return self.floor:get_position()
    end,
    visual = BillboardVisual.new({
      width = 16,
      height = 48,
      draw = function(width, height)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.line(width * 0.5, height, width * 0.5, 0)
        love.graphics.circle("line", width * 0.5, 0, width * 0.5)
      end
    })
  })

  -- This temporary billboard makes the door easy to inspect inside the projected view.
  self.projected_billboards:add_entry({
    id = "door",
    position_provider = function()
      return self.door:get_position()
    end,
    visual = BillboardVisual.new({
      width = 500,
      height = 800,
      draw = function(width, height)
        love.graphics.setColor(0, 0, 1, 1)
        love.graphics.rectangle("fill", 0, 0, width, height)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.circle("line", width - 30, height * 0.5, 20)
      end
    })
  })

  -- This entry keeps the manual bouncing-ball animation test outside the entity visual pipeline.
  self.projected_billboards:add_entry({
    id = "bounce_ball",
    position_provider = function()
      return self.bounce_ball:get_position()
    end,
    visual = ball_animation_visual
  })

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
  love.graphics.print("Active events: " .. self.runtime:get_active_event_count(), 20, 100)

  -- These values expose the current Box2D state of the bouncing-ball test.
  local velocity_x, velocity_y = self.box2d:get_linear_velocity(self.bounce_ball)
  local angular_velocity = self.box2d:get_angular_velocity(self.bounce_ball)

  love.graphics.print(string.format("Ball velocity: %.2f, %.2f", velocity_x, velocity_y), 20, 130)
  love.graphics.print(string.format("Angular velocity: %.4f", angular_velocity), 20, 150)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 20, 180)
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

  -- The ball remains a renderer-owned animation until this temporary test is migrated or removed.
  self.ball_animation:update(dt)
end

-- Draws all configured render layers in their current order.
function TestSceneRenderer:draw()
  -- The layer stack owns ordering and applies each configured view before drawing.
  self.layers:draw({
    renderer = self
  })
end

return TestSceneRenderer
