local TestSceneRenderer = require("project.test_scene_renderer")
local EntityVisualBillboardSource = require("engine.render.entity_visual_billboard_source")

local TestSceneRendererFactory = {}

-- Creates the test renderer with the project-specific rendering dependencies it requires.
function TestSceneRendererFactory.create(options)
  assert(type(options) == "table", "test scene renderer factory requires options")
  assert(options.project_runtime ~= nil, "test scene renderer factory requires a project runtime")

  -- This runtime system owns the animated entity visual instances configured by the project.
  local animated_entity_visuals = options.project_runtime:get_system("animated_entity_visuals")

  assert(animated_entity_visuals ~= nil,
    "test scene renderer factory requires the animated_entity_visuals runtime system")

  -- This source adapts the runtime visual collection to the billboard source contract.
  local projected_character_billboard_source =
    EntityVisualBillboardSource.new(animated_entity_visuals)

  -- This table preserves the options supplied by ProjectRuntime and adds renderer-specific dependencies.
  local renderer_options = {}

  for name, value in pairs(options) do
    renderer_options[name] = value
  end

  -- The renderer consumes this source without needing to know which runtime system produced it.
  renderer_options.projected_character_billboard_source =
    projected_character_billboard_source

  -- The final renderer receives all dependencies already resolved by this composition factory.
  return TestSceneRenderer.new(renderer_options)
end

return TestSceneRendererFactory