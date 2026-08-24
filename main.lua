local love = require "love"

local coreFolder = "engine/core/"
local Actrune = require(coreFolder .. "actrune")
local FixedStep = require(coreFolder .. "time.fixed_step")

local actionFolder = coreFolder .. "actions/"
local ActionAxis = require(actionFolder .. "action_axis")
local ActionActivation = require(actionFolder .. "actions_activation")
local ActionVector = require(actionFolder .. "action_vector")

local valueFolder = coreFolder .. "values/"
local Value = require(valueFolder .. "value")

local eventFolder = "engine/events/"
local Event = require(eventFolder .. "event")
local EventPage = require(eventFolder .. "event_page")
local DirectionalAreaTrigger = require(eventFolder .. "triggers.directional_area_trigger")

local commandFolder = eventFolder .. "commands/"
local CallCommand = require(commandFolder .. "call_command")
local WaitCommand = require(commandFolder .. "wait_command")

local worldFolder = "engine/world/"
local Entity = require(worldFolder .. "entity")

local movementFolder = worldFolder .. "movement/"
local Velocity = require(movementFolder .. "velocity")
local Translation = require(movementFolder .. "translation.translation")
local FacingDirection = require(movementFolder .. "direction.facing_direction")
local Rotation = require(movementFolder .. "rotation.rotation")

local spatialFolder = worldFolder .. "spatial/"
local PolygonShape = require(spatialFolder .. "polygon_shape")
local SpatialMover = require(spatialFolder .. "spatial_mover")

local physicsFolder = worldFolder .. "physics/"
local PhysicalMaterial = require(physicsFolder .. "physical_material")
local Box2DBackend = require(physicsFolder .. "backends.box2d_backend")


local runtime
local physics_step
local box2d

local event_entity
local player_entity
local player_translation
local player_direction
local player_rotation
local player_rotation_amount
local player_turn_axis
local player_move_input
local player_velocity

local bounce_ball
local test_ball
local test_floor

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

-- Draws a named polygon shape belonging to an Actrune entity.
local function draw_shape(entity, shape_name)
    local shape = entity:get_shape(shape_name)
    if shape == nil then return end
    love.graphics.polygon("line", shape:get_world_points(entity.transform))
end

-- Creates the directional interaction event used by the test scene.
local function create_test_event()
    return Event.new({
        id = "test_event",
        execution_mode = "single",
        pages = {
            EventPage.new({
                trigger = DirectionalAreaTrigger.new({
                    type = "interact",
                    shape = "interaction",
                    activator_shape = "collision",
                    max_angle = math.rad(60)
                }),
                commands = {
                    CallCommand.new(on_test_event_started),
                    WaitCommand.new(2),
                    CallCommand.new(on_test_event_finished)
                }
            })
        }
    })
end

-- Advances the Box2D simulation through one fixed physics step.
local function update_physics(step_dt)
    box2d:update(step_dt)
end

-- Creates the Actrune runtime, gameplay entities, and Box2D test scene.
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

    event_entity = Entity.new({
        id = "door",
        x = 200,
        y = 150,
        shapes = {
            interaction = PolygonShape.new({
                points = {
                    { x = -50, y = -40 },
                    { x = 50,  y = -40 },
                    { x = 50,  y = 40 },
                    { x = -50, y = 40 }
                }
            }),
            collision = PolygonShape.new({
                points = {
                    { x = -20, y = -40 },
                    { x = 20,  y = -40 },
                    { x = 20,  y = 40 },
                    { x = -20, y = 40 }
                }
            })
        }
    })

    player_entity = Entity.new({
        id = "player",
        x = 260,
        y = 150,
        rotation = math.rad(270),
        shapes = {
            collision = PolygonShape.new({
                points = {
                    { x = -15, y = -15 },
                    { x = 15,  y = -15 },
                    { x = 15,  y = 15 },
                    { x = -15, y = 15 }
                }
            })
        }
    })

    runtime:add_entity(event_entity)
    runtime:add_entity(player_entity)

    event_entity:add_event(create_test_event())

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

    local ball_material = PhysicalMaterial.new({
        density = 1,
        restitution = 0.6,
        friction = 0.3
    })

    local floor_material = PhysicalMaterial.new({
        restitution = 0.2,
        friction = 0.8
    })

    bounce_ball = Entity.new({
        id = "bounce_ball",
        x = 320,
        y = 200
    })

    runtime:add_entity(bounce_ball)

    box2d = Box2DBackend.new({
        gravity_x = 0,
        gravity_y = 980,
        sleep = true
    })

    test_ball = box2d:create_circle(
        "bounce_ball",
        bounce_ball.transform.x,
        bounce_ball.transform.y,
        10,
        {
            entity = bounce_ball,
            body_type = "dynamic",
            material = ball_material
        }
    )

    test_floor = box2d:create_rectangle(
        "floor",
        320,
        500,
        500,
        20,
        {
            body_type = "static",
            material = floor_material
        }
    )

    physics_step = FixedStep.new({
        step = 1 / 60,
        stall_threshold = 0.1,
        max_steps = 8
    })
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

-- Draws the gameplay scene, Box2D test objects, and diagnostic information.
function love.draw()
    love.graphics.print(table.concat(messages, "\n"), 20, 20)
    love.graphics.print("Active events: " .. runtime:get_active_event_count(), 20, 100)

    local velocity_x, velocity_y = test_ball.body:getLinearVelocity()
    local angular_velocity = test_ball.body:getAngularVelocity()

    love.graphics.print(string.format("Ball velocity: %.2f, %.2f", velocity_x, velocity_y), 20, 130)
    love.graphics.print(string.format("Angular velocity: %.4f", angular_velocity), 20, 150)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 20, 180)
    love.graphics.print("Fixed steps: " .. physics_step.last_steps, 20, 200)

    love.graphics.circle("line", bounce_ball.transform.x, bounce_ball.transform.y, 10)

    local angle = bounce_ball.transform.rotation
    local marker_x = bounce_ball.transform.x + math.cos(angle) * 10
    local marker_y = bounce_ball.transform.y + math.sin(angle) * 10
    love.graphics.line(bounce_ball.transform.x, bounce_ball.transform.y, marker_x, marker_y)

    local floor_points = { test_floor.body:getWorldPoints(test_floor.shape:getPoints()) }
    love.graphics.polygon("line", floor_points)

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
