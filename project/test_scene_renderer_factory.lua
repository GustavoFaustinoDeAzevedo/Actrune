local TestSceneRenderer = require("project.test_scene_renderer")
local EntityVisualBillboardSource = require("engine.render.entity_visual_billboard_source")
-- This project-specific source owns the temporary bouncing-ball visual animation.
local BounceBallBillboardSource = require("project.render.bounce_ball_billboard_source")

local TestSceneRendererFactory = {}

-- Creates the test renderer with the project-specific runtime dependencies it requires.
function TestSceneRendererFactory.create(options)
  assert(type(options) == "table", "test scene renderer factory requires options")
  assert(options.project_runtime ~= nil, "test scene renderer factory requires a project runtime")

  -- This runtime system owns the animated entity visual instances configured by the project.
  local animated_entity_visuals = options.project_runtime:get_system("animated_entity_visuals")

  assert(animated_entity_visuals ~= nil,
    "test scene renderer factory requires the animated_entity_visuals runtime system")

  -- This source adapts runtime entity visuals to the billboard source contract.
  local projected_character_billboard_source =
      EntityVisualBillboardSource.new(animated_entity_visuals)

  -- This runtime system owns the physics backend and fixed-step state used by diagnostics.
  local physics_system = options.project_runtime:get_system("physics")

  assert(physics_system ~= nil,
    "test scene renderer factory requires the physics runtime system")

  -- These are the narrow physics dependencies actually consumed by the renderer.
  local physics_backend = physics_system:get_backend()
  local physics_step = physics_system:get_fixed_step()

  assert(physics_backend ~= nil,
    "test scene renderer factory requires a physics backend")
  assert(physics_step ~= nil,
    "test scene renderer factory requires a physics fixed step")

  -- This entity is required by the temporary bouncing-ball projected visual.
  local bounce_ball = options.project.entities_by_id["bounce_ball"]

  assert(bounce_ball ~= nil,
    "test scene renderer factory requires the bounce_ball entity")

  -- This clip controls the timing of the temporary bouncing-ball animation.
  local ball_pulse_clip =
      options.project.resources.animation_clip:get("ball_pulse")

  assert(ball_pulse_clip ~= nil,
    "test scene renderer factory requires the ball_pulse animation clip")

  -- This source encapsulates the procedural frames and their independent playback state.
  local bounce_ball_billboard_source = BounceBallBillboardSource.new({
    entity_id = "bounce_ball",
    entity = bounce_ball,
    animation_clip = ball_pulse_clip
  })

  -- This table preserves normal renderer options without exposing ProjectRuntime as a service locator.
  local renderer_options = {}

  for name, value in pairs(options) do
    if name ~= "project_runtime" then
      renderer_options[name] = value
    end
  end

  -- These project-specific dependencies are resolved before renderer construction.
  renderer_options.projected_character_billboard_source =
      projected_character_billboard_source
  renderer_options.physics_backend = physics_backend
  renderer_options.physics_step = physics_step
  
  -- The renderer only needs the finished source, not its animation implementation details.
  renderer_options.bounce_ball_billboard_source =
      bounce_ball_billboard_source

  -- The renderer receives prepared dependencies and does not resolve runtime systems itself.
  return TestSceneRenderer.new(renderer_options)
end

return TestSceneRendererFactory
