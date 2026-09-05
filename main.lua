local love = require "love"

local ActruneProjectLoader = require("engine.core.project.actrune_project_loader")
local ProjectRuntime = require("engine.core.project.project_runtime")

local project_definition = require("project.project_definition")

-- This factory resolves project-specific renderer dependencies before creating the renderer.
local TestSceneRendererFactory = require("project.test_scene_renderer_factory")

local ProjectRuntimeConfiguration = require("project.runtime_configuration")

-- These resource types describe render data owned by the current project.
local ProjectRenderResourceTypes = require("project.render.resource_types")

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
    local project_loader = ActruneProjectLoader.new()

    -- This register groups extensions supplied by the current project under one provider.
    local project_register =
        project_loader:create_register("project")

    -- Runtime and rendering extensions use the same project-owned configuration boundary.
    ProjectRuntimeConfiguration.register(project_register)
    ProjectRenderResourceTypes.register(project_register)

    local configuration = project_loader:get_configuration()

    print(configuration:get_resource_provider("physical_material"))
    print(configuration:get_resource_provider("grid_metrics"))
    print(configuration:get_resource_provider("input_map"))
    print(configuration:get_resource_provider("control_profile"))

    project_loader:register_event_action("test_event_started", on_test_event_started)
    project_loader:register_event_action("test_event_finished", on_test_event_finished)

    return project_loader:load(project_definition)
end

-- Creates the current Actrune test project runtime.
function love.load()
    game = ProjectRuntime.new({
        project = load_project(),

        -- The project-specific factory injects the billboard sources required by the renderer.
        renderer_factory = TestSceneRendererFactory.create,
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
