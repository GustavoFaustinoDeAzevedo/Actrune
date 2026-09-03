local love = require "love"
local Camera2D = require("engine.render.camera_2d")
local CameraPositionControl = require("engine.render.camera_position_control")
local EntityPositionPolicy = require("engine.render.camera_position.entity_position_policy")
local SpatialDebugRenderer = require("engine.debug.spatial_debug_renderer")
local PositionResponse = require("engine.render.camera_position.position_response")
local RenderLayer = require("engine.render.render_layer")
local RenderLayerStack = require("engine.render.render_layer_stack")
local LayerTransform2D = require("engine.render.layer_transform_2d")
local RenderViewStack = require("engine.render.render_view_stack")
local CanvasRenderView = require("engine.render.canvas_render_view")
local WorldRegionView = require("engine.render.world_region_view")
local ProjectedWorldPlane = require("project.render.projections.projected_world_plane")
local RenderLayerGroup = require("engine.render.render_layer_group")
local ProjectedBillboardRenderer = require("engine.render.projected_billboard_renderer")
local OrientedOffsetPositionPolicy = require("engine.render.camera_position.oriented_offset_position_policy")
local CameraRotationControl = require("engine.render.camera_rotation_control")
local EntityRotationPolicy = require("engine.render.camera_rotation.entity_rotation_policy")
local RotationResponse = require("engine.render.camera_rotation.rotation_response")
local BillboardVisual = require("engine.render.billboard_visual")
local AnimationPlayer = require("engine.core.animation.animation_player")
local IndexedBillboardVisual = require("engine.render.indexed_billboard_visual")
local AnimatedEntityVisualSystem = require("engine.render.animated_entity_visual_system")




local TestSceneRenderer = {}
TestSceneRenderer.__index = TestSceneRenderer

-- Creates the renderer used by the current Actrune test project.
function TestSceneRenderer.new(options)
  options = options or {}

  local self = setmetatable({}, TestSceneRenderer)

  self.project = options.project
  self.runtime = options.runtime
  self.messages = options.messages or {}

  assert(self.project ~= nil, "test scene renderer requires a project")
  assert(self.runtime ~= nil, "test scene renderer requires a runtime")
  assert(options.project_runtime ~= nil, "test scene renderer requires a project runtime")

  local physics_system = options.project_runtime:get_system("physics")
  assert(physics_system ~= nil, "test scene renderer requires the physics runtime system")

  self.box2d = physics_system:get_backend()
  self.physics_step = physics_system:get_fixed_step()

  self.bounce_ball = self.project.entities_by_id["bounce_ball"]
  self.floor = self.project.entities_by_id["floor"]
  self.door = self.project.entities_by_id["door"]
  self.player = self.project.entities_by_id["player"]
  self.step_player = self.project.entities_by_id["step_player"]
  self.small_grid_area = self.project.entities_by_id["small_grid_area"]
  self.large_grid_area = self.project.entities_by_id["large_grid_area"]
  self.free_area = self.project.entities_by_id["free_area"]

  local projected_character_bindings = self.project.resources.directional_image_animation_binding_sequence:get(
    "projected_characters")

  local ball_pulse_clip = self.project.resources.animation_clip:get("ball_pulse")

  local player_x, player_y = self.player:get_position()

  self.camera = Camera2D.new({
    x = player_x,
    y = player_y
  })

  self.projected_camera = Camera2D.new({
    x = player_x,
    y = player_y,
    rotation = self.player:get_rotation()
  })

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

  self.projected_camera_offset = OrientedOffsetPositionPolicy.new(
    EntityPositionPolicy.new(self.player),
    function()
      return self.projected_camera:get_rotation()
    end,
    {
      forward = -96
    }
  )

  self.projected_camera_position = CameraPositionControl.new(
    self.projected_camera,
    self.projected_camera_offset,
    {
      response = PositionResponse.new({
        half_life = 0.08
      })
    }
  )

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


  self.ground_transform = LayerTransform2D.new()
  self.layers = RenderLayerStack.new()
  self.ground_region_size = 2048

  local projected_x, projected_y = self.projected_camera:get_position()
  local half_region = self.ground_region_size * 0.5

  self.ground_world_region = WorldRegionView.new({
    min_x = projected_x - half_region,
    min_y = projected_y - half_region,
    max_x = projected_x + half_region,
    max_y = projected_y + half_region
  })

  self.ground_projection = ProjectedWorldPlane.new({
    viewpoint = self.projected_camera,
    source_region = self.ground_world_region,
    horizon = 0.3,
    near_distance = 32,
    far_distance = 800,
    horizontal_fov = math.rad(75)
  })

  self.billboard_renderer = ProjectedBillboardRenderer.new(self.ground_projection)

  self.ground_canvas = CanvasRenderView.new({
    presenter = self.ground_projection
  })

  self.projected_world = RenderLayerGroup.new({
    name = "projected_world",
    order = 100,
    view = RenderViewStack.new({
      self.ground_canvas,
      self.ground_world_region
    })
  })

  self.projected_world:add(RenderLayer.new({
    name = "ground",
    order = 100,
    view = self.ground_transform,
    draw = function()
      self:_draw_ground()
    end
  }))

  self.projected_world:add(RenderLayer.new({
    name = "ground_debug",
    order = 200,
    draw = function()
      self:_draw_ground_debug()
    end
  }))

  self.layers:add(self.projected_world)

  self.layers:add(RenderLayer.new({
    name = "projected_billboards",
    order = 150,
    draw = function()
      self:_draw_projected_billboards()
    end
  }))

  self.layers:add(RenderLayer.new({
    name = "world",
    order = 200,
    view = self.camera,
    draw = function()
      self:_draw_world()
    end
  }))

  self.layers:add(RenderLayer.new({
    name = "screen",
    order = 1000,
    draw = function()
      self:_draw_diagnostics()
    end
  }))

  self.layers:add(RenderLayer.new({
    name = "player coordinates",
    order = 1100,
    draw = function()
      self:_draw_player_coordinates()
    end
  }))

  self.layers:add(RenderLayer.new({
    name = "door coordinates",
    order = 1200,
    draw = function()
      self:_draw_door_coordinates()
    end
  }))

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

  self.ball_animation = AnimationPlayer.new(ball_pulse_clip)

  local ball_animation_visual = IndexedBillboardVisual.new({
    visuals = {
      ball_frame_a,
      ball_frame_b,
      ball_frame_c,
      ball_frame_b,
    },
    index_provider = function()
      return self.ball_animation:get_frame_index()
    end
  })

  self.projected_character_visuals = AnimatedEntityVisualSystem.new(
    self.project.entities_by_id,
    projected_character_bindings
  )

  self.projected_character_visuals:get(2):get_animation():set_playback_rate(0.25)

  local projected_character_billboards = {}

  for index = 1, self.projected_character_visuals:get_count() do
    local entity_visual = self.projected_character_visuals:get(index)

    projected_character_billboards[index] = {
      id = entity_visual:get_entity_id(),
      position_provider = function()
        return entity_visual:get_position()
      end,
      rotation_provider = function()
        return entity_visual:get_rotation()
      end,
      visual = entity_visual:get_visual()
    }
  end

  self.projected_billboards = {}

  for _, billboard in ipairs(projected_character_billboards) do
    table.insert(self.projected_billboards, billboard)
  end

  table.insert(self.projected_billboards, {
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

  table.insert(self.projected_billboards, {
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

  table.insert(self.projected_billboards, {
    position_provider = function()
      return self.bounce_ball:get_position()
    end,
    visual = ball_animation_visual
  })

  return self
end

-- Draws vertical world entities through the current perspective projection.
function TestSceneRenderer:_draw_projected_billboards()
  local canvas = self.ground_canvas:get_canvas()
  local width, height = canvas:getDimensions()

  self.billboard_renderer:draw(
    self.projected_billboards,
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

function TestSceneRenderer:_draw_player_coordinates()
  local player_x, player_y = self.player:get_position()
  love.graphics.print(string.format("Player position: %.2f, %.2f", player_x, player_y), 20, 250)
end

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
  self.camera_position:update(dt)

  self.projected_camera_rotation:update(dt)
  self.projected_camera_position:update(dt)

  local projected_x, projected_y = self.projected_camera:get_position()
  local half_region = self.ground_region_size * 0.5

  self.ground_world_region:set_bounds(
    projected_x - half_region,
    projected_y - half_region,
    projected_x + half_region,
    projected_y + half_region
  )

  self.ball_animation:update(dt)
  self.projected_character_visuals:update(dt)
end

-- Draws all configured render layers in their current order.
function TestSceneRenderer:draw()
  self.layers:draw({
    renderer = self
  })
end

return TestSceneRenderer
