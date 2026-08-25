local love = require "love"

local coreFolder = "engine/core/"
local Actrune = require(coreFolder .. "actrune")
local FixedStep = require(coreFolder .. "time.fixed_step")
local ProjectLoader = require(coreFolder .. "project.project_loader")

local actionFolder = coreFolder .. "actions/"
local ActionAxis = require(actionFolder .. "action_axis")
local ActionActivation = require(actionFolder .. "actions_activation")
local ActionVector = require(actionFolder .. "action_vector")

local valueFolder = coreFolder .. "values/"
local Value = require(valueFolder .. "value")

local worldFolder = "engine/world/"

local movementFolder = worldFolder .. "movement/"
local Velocity = require(movementFolder .. "velocity")
local Translation = require(movementFolder .. "translation.translation")
local FacingDirection = require(movementFolder .. "direction.facing_direction")
local Rotation = require(movementFolder .. "rotation.rotation")

local spatialFolder = worldFolder .. "spatial/"
local SpatialMover = require(spatialFolder .. "spatial_mover")

local physicsFolder = worldFolder .. "physics/"
local Box2DBackend = require(physicsFolder .. "backends.box2d_backend")
local PhysicalMaterialFactory = require(physicsFolder .. "physical_material_factory")

local project_definition = require("project.project_definition")

local runtime
local physics_step
local box2d
local project

local event_entity
local player_entity
local bounce_ball
local floor_entity

local player_translation
local player_direction
local player_rotation
local player_rotation_amount
local player_turn_axis
local player_move_input
local player_velocity

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

-- Loads project resources, entities, and serialized events.
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

    project_loader:register_event_action("test_event_started", on_test_event_started)
    project_loader:register_event_action("test_event_finished", on_test_event_finished)

    project = project_loader:load(project_definition)

    bounce_ball = project.entities_by_id["bounce_ball"]
    floor_entity = project.entities_by_id["floor"]
    event_entity = project.entities_by_id["door"]
    player_entity = project.entities_by_id["player"]

    for _, entity in ipairs(project.entities) do runtime:add_entity(entity) end
end

-- Creates the current player movement configuration.
local function create_player_movement()
    player_velocity = Velocity.new()

    player_move_input = ActionVector.new({
        x_axis = ActionAxis.new({
            negative_action = "move_left",
            positive_action = "move_right",
            activation = ActionActivation.new("down")
        }),

        y_axis = ActionAxis.new({
            negative_action = "move_up",
            positive_action = "move_down",
            activation = ActionActivation.new("down")
        })
    })

    player_turn_axis = ActionAxis.new({
        negative_action = "turn_left",
        positive_action = "turn_right",
        activation = ActionActivation.new("pressed")
    })

    player_rotation_amount = Value.new(math.rad(90))
    player_direction = FacingDirection.new()
    player_rotation = Rotation.new(player_entity.transform)

    local player_mover = SpatialMover.new(runtime.world, player_entity, {
        source_shape = "collision",
        target_shape = "collision"
    })

    player_translation = Translation.new(player_mover)
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

    runtime:bind_key("interact", "space")
    runtime:bind_key("move_up", "w")
    runtime:bind_key("move_left", "a")
    runtime:bind_key("move_down", "s")
    runtime:bind_key("move_right", "d")
    runtime:bind_key("turn_left", "q")
    runtime:bind_key("turn_right", "e")

    runtime:bind_spatial_action("interact", {
        activator_shape = "collision",
        target_shape = "interaction",
        trigger = "interact"
    })

    load_project()
    create_player_movement()
    create_physics()
end

-- Processes gameplay input and advances physics and runtime systems.
function love.update(dt)
    local move_x, move_y = player_move_input:resolve(runtime)
    local turn_direction = player_turn_axis:resolve(runtime)
    local rotation_angle = turn_direction * player_rotation_amount:resolve({ dt = dt })

    player_rotation:turn(rotation_angle)

    local direction_x, direction_y = player_direction:resolve(move_x, move_y, player_entity.transform)
    local movement_speed = 120

    player_velocity:set(direction_x * movement_speed, direction_y * movement_speed)

    local movement_x, movement_y = player_velocity:get_displacement(dt)
    player_translation:move(movement_x, movement_y)

    if runtime:is_action_pressed("interact") then runtime:trigger_spatial_action("interact", player_entity) end

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
end

-- Forwards keyboard press events from LÖVE to the Actrune runtime.
function love.keypressed(key)
    runtime:key_pressed(key)
end

-- Forwards keyboard release events from LÖVE to the Actrune runtime.
function love.keyreleased(key)
    runtime:key_released(key)
end
