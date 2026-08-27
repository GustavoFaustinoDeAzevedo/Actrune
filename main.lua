local love = require "love"

local ProjectLoader = require("engine.core.project.project_loader")
local ProjectRuntime = require("engine.core.project.project_runtime")

local InputMapFactory = require("engine.core.input.input_map_factory")
local GridMetricsFactory = require("engine.world.grid.grid_metrics_factory")
local ControlProfileFactory = require("engine.world.control.control_profile_factory")
local PhysicalMaterialFactory = require("engine.world.physics.physical_material_factory")

local project_definition = require("project.project_definition")
local TestSceneRenderer = require("project.test_scene_renderer")

local game
local messages = {}

-- Adds a message to the current test output.
local function add_message(message)
    table.insert(messages, message)
end

-- Adds the test event start message.
local function on_test_event_started()
    add_message("Evento iniciado.")
end

-- Adds the test event completion message.
local function on_test_event_finished()
    add_message("Evento finalizado.")
end

-- Loads and validates the current project definition.
local function load_project()
    local project_loader = ProjectLoader.new()

    project_loader:register_resource_type(
        "physical_material",
        PhysicalMaterialFactory.create,
        {
            fields = {
                {
                    name = "properties",
                    type = "property_map",
                    allow_custom = true,

                    suggestions = {
                        { name = "density",     type = "number", min = 0 },
                        { name = "restitution", type = "number", min = 0 },
                        { name = "friction",    type = "number", min = 0 }
                    }
                }
            }
        }
    )

    project_loader:register_resource_type(
        "grid_metrics",
        GridMetricsFactory.create,
        {
            fields = {
                { name = "cell_width",  type = "number", required = true, min_exclusive = 0 },
                { name = "cell_height", type = "number", required = true, min_exclusive = 0 }
            }
        }
    )

    project_loader:register_resource_type("input_map", InputMapFactory.create)
    project_loader:register_resource_type("control_profile", ControlProfileFactory.create)

    project_loader:register_event_action("test_event_started", on_test_event_started)
    project_loader:register_event_action("test_event_finished", on_test_event_finished)

    return project_loader:load(project_definition)
end

-- Creates the renderer used by the current development project.
local function create_renderer(options)
    options.messages = messages
    return TestSceneRenderer.new(options)
end

-- Creates the current Actrune test project runtime.
function love.load()
    game = ProjectRuntime.new({
        project = load_project(),
        renderer_factory = create_renderer
    })
end

-- Advances the current project runtime.
function love.update(dt)
    game:update(dt)
end

-- Draws the current project runtime.
function love.draw()
    game:draw()
end

-- Forwards keyboard press events to the project runtime.
function love.keypressed(key)
    game:key_pressed(key)
end

-- Forwards keyboard release events to the project runtime.
function love.keyreleased(key)
    game:key_released(key)
end
