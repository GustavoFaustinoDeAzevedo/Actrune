local love = require "love"

local coreFolder = "engine/core/"
local Actrune = require(coreFolder .. "actrune")
local FixedStep = require(coreFolder .. "time.fixed_step")
local ProjectLoader = require(coreFolder .. "project.project_loader")

local inputFolder = coreFolder .. "input/"
local InputMapFactory = require(inputFolder .. "input_map_factory")

local worldFolder = "engine/world/"

local gridFolder = worldFolder .. "grid/"
local GridMetricsFactory = require(gridFolder .. "grid_metrics_factory")
local GridContextSystem = require(gridFolder .. "grid_context_system")

local controlFolder = worldFolder .. "control/"
local ControlProfileFactory = require(controlFolder .. "control_profile_factory")
local ControlSystem = require(controlFolder .. "control_system")

local physicsFolder = worldFolder .. "physics/"
local Box2DBackend = require(physicsFolder .. "backends.box2d_backend")
local PhysicalMaterialFactory = require(physicsFolder .. "physical_material_factory")

local project_definition = require("project.project_definition")
local TestSceneRenderer = require("project.test_scene_renderer")

local runtime
local physics_step
local box2d
local control_system
local grid_context_system
local project
local renderer

local messages = {}

-- Adds a message to the test output.
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

-- Loads project resources, entities, controls, input configuration, and serialized events.
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
                { name = "cell_size", type = "number", required = true, min_exclusive = 0 }
            }
        }
    )

    project_loader:register_resource_type("input_map", InputMapFactory.create)
    project_loader:register_resource_type("control_profile", ControlProfileFactory.create)

    project_loader:register_event_action("test_event_started", on_test_event_started)
    project_loader:register_event_action("test_event_finished", on_test_event_finished)

    project = project_loader:load(project_definition)

    for _, entity in ipairs(project.entities) do runtime:add_entity(entity) end

    local input_map = project.resources["input_map"]:get("default")
    input_map:bind(runtime)
end

-- Creates the system that resolves active grid areas for project entities.
local function create_grid_contexts()
    grid_context_system = GridContextSystem.new()
    grid_context_system:add_project(project)
    grid_context_system:update()
end

-- Creates and registers all control-driven project components.
local function create_controls()
    control_system = ControlSystem.new(runtime.world)
    control_system:add_project(project)
end

-- Creates the physics backend and registers all project rigid bodies.
local function create_physics()
    box2d = Box2DBackend.new({
        gravity_x = 0,
        gravity_y = 980,
        sleep = true
    })

    for _, entity in ipairs(project.entities) do
        if entity:get_component("rigid_body") ~= nil then box2d:add_entity(entity) end
    end

    physics_step = FixedStep.new({
        step = 1 / 60,
        stall_threshold = 0.1,
        max_steps = 8
    })
end

-- Creates the renderer used by the current development project.
local function create_renderer()
    renderer = TestSceneRenderer.new({
        project = project,
        runtime = runtime,
        box2d = box2d,
        physics_step = physics_step,
        messages = messages
    })
end

-- Advances the Box2D simulation through one fixed physics step.
local function update_physics(step_dt)
    box2d:update(step_dt)
end

-- Creates the Actrune runtime and current project scene.
function love.load()
    runtime = Actrune.new()

    load_project()
    create_grid_contexts()
    create_controls()
    create_physics()
    create_renderer()
end

-- Advances spatial contexts, project controls, physics, and runtime systems.
function love.update(dt)
    grid_context_system:update()
    control_system:update(runtime, dt)
    physics_step:update(dt, update_physics)
    runtime:update(dt)
end

-- Draws the current project through its configured renderer.
function love.draw()
    renderer:draw()
end

-- Forwards keyboard press events from LÖVE to the Actrune runtime.
function love.keypressed(key)
    runtime:key_pressed(key)
end

-- Forwards keyboard release events from LÖVE to the Actrune runtime.
function love.keyreleased(key)
    runtime:key_released(key)
end
