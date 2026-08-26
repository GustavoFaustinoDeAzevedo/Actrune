local love = require "love"

local coreFolder = "engine/core/"
local Actrune = require(coreFolder .. "actrune")
local FixedStep = require(coreFolder .. "time.fixed_step")
local ProjectLoader = require(coreFolder .. "project.project_loader")

local inputFolder = coreFolder .. "input/"
local InputMapFactory = require(inputFolder .. "input_map_factory")

local worldFolder = "engine/world/"

local controlFolder = worldFolder .. "control/"
local ControlProfileFactory = require(controlFolder .. "control_profile_factory")
local ControlSystem = require(controlFolder .. "control_system")

local physicsFolder = worldFolder .. "physics/"
local Box2DBackend = require(physicsFolder .. "backends.box2d_backend")
local PhysicalMaterialFactory = require(physicsFolder .. "physical_material_factory")

local project_definition = require("project.project_definition")

local runtime
local physics_step
local box2d
local control_system
local project

local event_entity
local player_entity
local step_player_entity
local bounce_ball
local floor_entity

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

-- Draws a named spatial shape belonging to an Actrune entity.
local function draw_shape(entity, shape_name)
    local shape = entity:get_shape(shape_name)
    if shape == nil then return end
    love.graphics.polygon("line", shape:get_world_points(entity.transform))
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

    project_loader:register_resource_type("input_map", InputMapFactory.create)
    project_loader:register_resource_type("control_profile", ControlProfileFactory.create)

    project_loader:register_event_action("test_event_started", on_test_event_started)
    project_loader:register_event_action("test_event_finished", on_test_event_finished)

    project = project_loader:load(project_definition)

    bounce_ball = project.entities_by_id["bounce_ball"]
    floor_entity = project.entities_by_id["floor"]
    event_entity = project.entities_by_id["door"]
    player_entity = project.entities_by_id["player"]
    step_player_entity = project.entities_by_id["step_player"]

    for _, entity in ipairs(project.entities) do runtime:add_entity(entity) end

    local input_map = project.resources["input_map"]:get("default")
    input_map:bind(runtime)
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

-- Advances the Box2D simulation through one fixed physics step.
local function update_physics(step_dt)
    box2d:update(step_dt)
end

-- Creates the Actrune runtime and current project scene.
function love.load()
    runtime = Actrune.new()

    load_project()
    create_controls()
    create_physics()
end

-- Advances project controls, physics, and runtime systems.
function love.update(dt)
    control_system:update(runtime, dt)
    physics_step:update(dt, update_physics)
    runtime:update(dt)
end

-- Draws the current project scene and diagnostic information.
function love.draw()
    love.graphics.print(table.concat(messages, "\n"), 20, 20)
    love.graphics.print("Active events: " .. runtime:get_active_event_count(), 20, 100)

    local velocity_x, velocity_y = box2d:get_linear_velocity(bounce_ball)
    local angular_velocity = box2d:get_angular_velocity(bounce_ball)

    love.graphics.print(string.format("Ball velocity: %.2f, %.2f", velocity_x, velocity_y), 20, 130)
    love.graphics.print(string.format("Angular velocity: %.4f", angular_velocity), 20, 150)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 20, 180)
    love.graphics.print("Fixed steps: " .. physics_step.last_steps, 20, 200)
    love.graphics.print("WASD: continuous player | Arrows: 16 px step player", 20, 220)

    draw_shape(bounce_ball, "physics")
    draw_shape(floor_entity, "physics")

    local ball_shape = bounce_ball:get_shape("physics")
    local ball_radius = ball_shape:get_radius()
    local angle = bounce_ball.transform.rotation
    local marker_x = bounce_ball.transform.x + math.cos(angle) * ball_radius
    local marker_y = bounce_ball.transform.y + math.sin(angle) * ball_radius

    love.graphics.line(bounce_ball.transform.x, bounce_ball.transform.y, marker_x, marker_y)

    draw_shape(event_entity, "interaction")
    draw_shape(event_entity, "collision")
    draw_shape(player_entity, "collision")
    draw_shape(step_player_entity, "collision")
end

-- Forwards keyboard press events from LÖVE to the Actrune runtime.
function love.keypressed(key)
    runtime:key_pressed(key)
end

-- Forwards keyboard release events from LÖVE to the Actrune runtime.
function love.keyreleased(key)
    runtime:key_released(key)
end
