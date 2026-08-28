local love = require "love"
local Camera2D = require("engine.render.camera_2d")
local CameraPositionControl = require("engine.render.camera_position_control")
local EntityPositionPolicy = require("engine.render.camera_position.entity_position_policy")
local SpatialDebugRenderer = require("engine.debug.spatial_debug_renderer")
local PositionResponse = require("engine.render.camera_position.position_response")
local AxisAlignedBoundsConstraint = require("engine.render.camera_position.axis_aligned_bounds_constraint")

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

  local player_x, player_y = self.player:get_position()

  self.camera = Camera2D.new({
    x = player_x,
    y = player_y
  })

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
  return self
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

-- Draws the current interaction and player test shapes.
function TestSceneRenderer:_draw_entities()
  SpatialDebugRenderer.draw_shape(self.door, "interaction")
  SpatialDebugRenderer.draw_shape(self.door, "collision")
  SpatialDebugRenderer.draw_shape(self.player, "collision")
  SpatialDebugRenderer.draw_shape(self.step_player, "collision")
end

-- Draws the contextual grid test areas.
function TestSceneRenderer:_draw_grid_areas()
  SpatialDebugRenderer.draw_shape(self.small_grid_area, "area")
  SpatialDebugRenderer.draw_shape(self.large_grid_area, "area")
  SpatialDebugRenderer.draw_shape(self.free_area, "area")
end

-- Draws all world-space test content through the active camera.
function TestSceneRenderer:_draw_world()
  self.camera:begin()
  self:_draw_physics()
  self:_draw_entities()
  self:_draw_grid_areas()
  self.camera:finish()
end

-- Updates time-dependent rendering behavior before drawing.
function TestSceneRenderer:update(dt)
  self.camera_position:update(dt)
end

-- Draws the complete current Actrune test scene.
function TestSceneRenderer:draw()
  self:_draw_world()
  self:_draw_diagnostics()
end

return TestSceneRenderer
