local TestSceneRenderer = require("project.test_scene_renderer")
local EntityVisualBillboardSource = require("engine.render.entity_visual_billboard_source")

-- This project-specific source owns the temporary bouncing-ball visual animation.
local BounceBallBillboardSource = require("project.render.bounce_ball_billboard_source")

-- This project-specific source owns temporary projected scene inspection visuals.
local ProjectedDebugBillboardSource = require("project.render.projected_debug_billboard_source")

-- This system creates runtime representations for stateless entity visuals.
local StaticEntityVisualSystem = require("engine.render.static_entity_visual_system")

-- -------------------------------------------------------------------------- --
--                               Local Functions                              --
-- -------------------------------------------------------------------------- --

-- Resolves one required entity from the loaded project.
local function require_entity(project, id)
  local entity = project.entities_by_id[id]
  assert(entity ~= nil, "test scene renderer factory requires entity: " .. id)
  return entity
end

-- Resolves the runtime-backed source containing declarative animated entity visuals.
local function create_character_billboard_source(options)
  -- This runtime system owns the instantiated animated entity representations.
  local animated_entity_visuals =
      options.project_runtime:get_system("animated_entity_visuals")

  assert(animated_entity_visuals ~= nil,
    "test scene renderer factory requires the animated_entity_visuals runtime system")

  -- The source adapts runtime representations to the billboard source contract.
  return EntityVisualBillboardSource.new(animated_entity_visuals)
end

-- Resolves the narrow physics dependencies used only by renderer diagnostics.
local function resolve_physics_dependencies(options)
  local physics_system =
      options.project_runtime:get_system("physics")

  assert(physics_system ~= nil,
    "test scene renderer factory requires the physics runtime system")

  -- The renderer receives capabilities instead of the complete physics runtime system.
  local backend = physics_system:get_backend()
  local fixed_step = physics_system:get_fixed_step()

  assert(backend ~= nil,
    "test scene renderer factory requires a physics backend")
  assert(fixed_step ~= nil,
    "test scene renderer factory requires a physics fixed step")

  return backend, fixed_step
end

-- Resolves the render configuration selected by the current test scene.
local function resolve_render_configuration(project)
  local configurations = project.resources.test_scene_render_configuration

  assert(configurations ~= nil,
    "test scene renderer factory requires test_scene_render_configuration resources")

  -- This factory represents the main test scene, so selecting its main configuration belongs here.
  local configuration = configurations:get("main")

  assert(configuration ~= nil,
    "test scene renderer factory requires the main test scene render configuration")

  return configuration
end

-- Resolves the live entities referenced by the configured camera target ids.
local function resolve_camera_targets(project, configuration)
  local world_target_id =
      configuration:get_world_camera_target_entity()

  local projected_target_id =
      configuration:get_projected_camera_target_entity()

  -- Serialized entity ids become live runtime objects only at this composition boundary.
  local world_target =
      require_entity(project, world_target_id)

  local projected_target =
      require_entity(project, projected_target_id)

  assert(type(world_target.get_position) == "function",
    "world camera target must expose get_position")

  assert(type(projected_target.get_position) == "function"
    and type(projected_target.get_rotation) == "function",
    "projected camera target must expose get_position and get_rotation")

  return world_target, projected_target
end

-- Creates the project-specific procedural billboard sources used by this test scene.
local function create_test_billboard_sources(project)
  local bounce_ball = require_entity(project, "bounce_ball")
  local floor = require_entity(project, "floor")
  local door = require_entity(project, "door")

  -- This clip supplies timing while the source owns the procedural ball frames.
  local ball_pulse_clip =
      project.resources.animation_clip:get("ball_pulse")

  assert(ball_pulse_clip ~= nil,
    "test scene renderer factory requires the ball_pulse animation clip")

  local bounce_ball_source = BounceBallBillboardSource.new({
    entity_id = "bounce_ball",
    entity = bounce_ball,
    animation_clip = ball_pulse_clip
  })

  -- These visuals are intentionally project-side because they exist only for development inspection.
  local debug_source = ProjectedDebugBillboardSource.new({
    floor = floor,
    door = door
  })

  return bounce_ball_source, debug_source
end

-- Creates the billboard source backed by declarative static entity visual bindings.
local function create_static_billboard_source(project)
  local binding_sequences =
      project.resources.image_billboard_binding_sequence

  assert(binding_sequences ~= nil,
    "test scene renderer factory requires image_billboard_binding_sequence resources")

  -- This sequence selects which static entity representations belong to the projected test scene.
  local bindings =
      binding_sequences:get("projected_static_entities")

  assert(bindings ~= nil,
    "test scene renderer factory requires the projected_static_entities binding sequence")

  -- The system resolves binding entity ids into live runtime representations.
  local static_visuals = StaticEntityVisualSystem.new(
    project.entities_by_id,
    bindings
  )

  -- The existing billboard source works because static and animated representations expose the same render interface.
  return EntityVisualBillboardSource.new(static_visuals)
end

-- -------------------------------------------------------------------------- --

local TestSceneRendererFactory = {}

-- Creates the test renderer with all project-specific dependencies already resolved.
function TestSceneRendererFactory.create(options)
  assert(type(options) == "table",
    "test scene renderer factory requires options")
  assert(options.project ~= nil,
    "test scene renderer factory requires a project")
  assert(options.project_runtime ~= nil,
    "test scene renderer factory requires a project runtime")
  assert(options.runtime ~= nil
    and type(options.runtime.get_active_event_count) == "function",
    "test scene renderer factory requires an event runtime exposing get_active_event_count")

  -- Each helper resolves one independent dependency group at the project composition boundary.
  local character_source =
      create_character_billboard_source(options)

  local physics_backend, physics_step =
      resolve_physics_dependencies(options)

  local render_configuration =
      resolve_render_configuration(options.project)

  local world_camera_target, projected_camera_target =
      resolve_camera_targets(options.project, render_configuration)

  local bounce_ball_source, debug_source =
      create_test_billboard_sources(options.project)

  -- Static entity visuals are built from their own declarative binding sequence.
  local static_billboard_source =
      create_static_billboard_source(options.project)

  -- This provider exposes only the event metric consumed by screen diagnostics.
  local active_event_count_provider = function()
    return options.runtime:get_active_event_count()
  end

  -- Runtime service locators are deliberately not forwarded to the renderer.
  local renderer_options = {}

  for name, value in pairs(options) do
    if name ~= "project_runtime" and name ~= "runtime" then
      renderer_options[name] = value
    end
  end

  -- This source contributes stateless entity representations to the projected billboard composition.
  renderer_options.static_test_billboard_source =
      static_billboard_source

  -- Billboard sources are injected independently so their implementations remain outside the renderer.
  renderer_options.projected_character_billboard_source =
      character_source
  renderer_options.bounce_ball_billboard_source =
      bounce_ball_source
  renderer_options.projected_debug_billboard_source =
      debug_source

  -- Diagnostics receive only the physics capabilities and event metric they consume.
  renderer_options.physics_backend =
      physics_backend
  renderer_options.physics_step =
      physics_step
  renderer_options.active_event_count_provider =
      active_event_count_provider

  -- Camera and projection behavior comes from validated project data.
  renderer_options.render_configuration =
      render_configuration
  renderer_options.world_camera_target =
      world_camera_target
  renderer_options.projected_camera_target =
      projected_camera_target

  -- The renderer is constructed only after every external dependency has been resolved.
  return TestSceneRenderer.new(renderer_options)
end

return TestSceneRendererFactory
