local TestSceneRenderer = require("project.test_scene_renderer")
local EntityVisualBillboardSource = require("engine.render.entity_visual_billboard_source")

-- This project-specific source owns the temporary bouncing-ball visual animation.
local BounceBallBillboardSource = require("project.render.bounce_ball_billboard_source")

-- This project-specific source owns temporary projected scene inspection visuals.
local ProjectedDebugBillboardSource = require("project.render.projected_debug_billboard_source")

local TestSceneRendererFactory = {}

-- Creates the test renderer with the project-specific runtime dependencies it requires.
function TestSceneRendererFactory.create(options)
  assert(type(options) == "table", "test scene renderer factory requires options")
  assert(options.project_runtime ~= nil, "test scene renderer factory requires a project runtime")

  -- This resource contains the camera and projection values selected by the current test scene.
  local render_configurations =
      options.project.resources.test_scene_render_configuration

  assert(render_configurations ~= nil,
    "test scene renderer factory requires test_scene_render_configuration resources")

  -- The project currently uses one render configuration for its main test scene.
  local render_configuration =
      render_configurations:get("main")

  assert(render_configuration ~= nil,
    "test scene renderer factory requires the main test scene render configuration")

  assert(options.runtime ~= nil and type(options.runtime.get_active_event_count) == "function",
    "test scene renderer factory requires an event runtime exposing get_active_event_count")

  -- This provider exposes only the event metric required by the renderer diagnostics.
  local active_event_count_provider = function()
    return options.runtime:get_active_event_count()
  end

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

  -- These entities drive the temporary projected debug visuals.
  local floor = options.project.entities_by_id["floor"]
  local door = options.project.entities_by_id["door"]

  assert(floor ~= nil,
    "test scene renderer factory requires the floor entity")
  assert(door ~= nil,
    "test scene renderer factory requires the door entity")

  -- This source isolates project-specific procedural debug billboards from the renderer.
  local projected_debug_billboard_source = ProjectedDebugBillboardSource.new({
    floor = floor,
    door = door
  })

  -- This table keeps normal renderer options while hiding runtime service locators from the renderer.
  local renderer_options = {}

  for name, value in pairs(options) do
    if name ~= "project_runtime" and name ~= "runtime" then
      renderer_options[name] = value
    end
  end

  -- Camera and projection behavior comes from project data instead of renderer constants.
  renderer_options.render_configuration =
      render_configuration

  -- These billboard sources provide independent projected visual origins.
  renderer_options.projected_character_billboard_source =
      projected_character_billboard_source
  renderer_options.bounce_ball_billboard_source =
      bounce_ball_billboard_source
  renderer_options.projected_debug_billboard_source =
      projected_debug_billboard_source

  -- These dependencies expose only the diagnostic capabilities consumed by the renderer.
  renderer_options.physics_backend = physics_backend
  renderer_options.physics_step = physics_step
  renderer_options.active_event_count_provider =
      active_event_count_provider


  -- The renderer only needs the finished source, not its animation implementation details.
  renderer_options.bounce_ball_billboard_source =
      bounce_ball_billboard_source

  -- The renderer receives prepared dependencies and does not resolve runtime systems itself.
  return TestSceneRenderer.new(renderer_options)
end

return TestSceneRendererFactory
