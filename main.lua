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

local physicsFolder = worldFolder .. "physics/"
local PhysicalMaterial = require(physicsFolder .. "physical_material")
local ContactMaterialResolver = require(physicsFolder .. "contact_material_resolver")
local PhysicsWorld = require(physicsFolder .. "physics_world")
local Mass = require(physicsFolder .. "mass")

local movementFolder = worldFolder .. "movement/"
local Velocity = require(movementFolder .. "velocity")
local Acceleration = require(movementFolder .. "acceleration")

local spatialFolder = worldFolder .. "spatial/"
local PolygonShape = require(spatialFolder .. "polygon_shape")
local SpatialMover = require(spatialFolder .. "spatial_mover")

local Translation = require(movementFolder .. "translation.translation")
local FacingDirection = require(movementFolder .. "direction.facing_direction")
local Rotation = require(movementFolder .. "rotation.rotation")

local runtime
local physics_world
local physics_step

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
local bounce_ball_b
local bounce_velocity
local bounce_velocity_b
local bounce_walls = {}

local messages = {}

local ball_points = {
    { x = 0,   y = -10 },
    { x = 4,   y = -9 },
    { x = 7,   y = -7 },
    { x = 9,   y = -4 },
    { x = 10,  y = 0 },
    { x = 9,   y = 4 },
    { x = 7,   y = 7 },
    { x = 4,   y = 9 },
    { x = 0,   y = 10 },
    { x = -4,  y = 9 },
    { x = -7,  y = 7 },
    { x = -9,  y = 4 },
    { x = -10, y = 0 },
    { x = -9,  y = -4 },
    { x = -7,  y = -7 },
    { x = -4,  y = -9 }
}

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

-- Draws a named polygon shape belonging to an entity.
local function draw_shape(entity, shape_name)
    local shape = entity:get_shape(shape_name)
    if shape == nil then return end

    love.graphics.polygon("line", shape:get_world_points(entity.transform))
end

-- Creates a rectangular static wall for the physics test.
local function create_bounce_wall(id, x, y, width, height, material)
    local half_width = width / 2
    local half_height = height / 2

    return Entity.new({
        id = id,
        x = x,
        y = y,
        shapes = {
            bounce = PolygonShape.new({
                material = material,
                points = {
                    { x = -half_width, y = -half_height },
                    { x = half_width,  y = -half_height },
                    { x = half_width,  y = half_height },
                    { x = -half_width, y = half_height }
                }
            })
        }
    })
end

-- Creates a dynamic ball with velocity, mass, and acceleration components.
local function create_bounce_ball(id, x, y, velocity_x, velocity_y, mass_value, material)
    local entity = Entity.new({
        id = id,
        x = x,
        y = y,
        shapes = {
            bounce = PolygonShape.new({
                material = material,
                points = ball_points
            })
        }
    })

    local velocity = Velocity.new({ x = velocity_x, y = velocity_y })

    entity:set_component("velocity", velocity)
    entity:set_component("mass", Mass.new(mass_value))
    entity:set_component("acceleration", Acceleration.new({ x = 0, y = 980 }))

    return entity, velocity
end

-- Creates the directional interaction event used by the current test scene.
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

-- Draws an entity's local forward direction for rotational debugging.
local function draw_forward(entity, length)
    local x = entity.transform.x
    local y = entity.transform.y
    local forward_x, forward_y = entity.transform:get_forward()

    love.graphics.line(x, y, x + forward_x * length, y + forward_y * length)
end

-- Advances the physics simulation by one fixed step.
local function update_physics(step_dt)
    physics_world:update(step_dt)
end

-- Creates the Actrune runtime and the current test scene.
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

    physics_step = FixedStep.new({
        step = 1 / 60,
        stall_threshold = 0.1,
        max_steps = 8
    })

    local bounce_ball_material = PhysicalMaterial.new({
        restitution = 1,
        static_friction = 0,
        dynamic_friction = 0
    })

    local bounce_wall_material = PhysicalMaterial.new({
        restitution = 0.5,
        static_friction = 0.9,
        dynamic_friction = 0.8
    })

    local bounce_material_resolver = ContactMaterialResolver.new({
        restitution_combiner = math.min,
        static_friction_combiner = function(a, b) return math.sqrt(a * b) end,
        dynamic_friction_combiner = function(a, b) return math.sqrt(a * b) end,
        default_restitution = 0,
        default_static_friction = 0,
        default_dynamic_friction = 0
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

    event_entity:add_event(create_test_event())

    bounce_ball, bounce_velocity = create_bounce_ball(
        "bounce_ball", 320, 350, 200, 0, 1, bounce_ball_material
    )

    bounce_ball_b, bounce_velocity_b = create_bounce_ball(
        "bounce_ball_b", 420, 350, -50, 0, 1, bounce_ball_material
    )

    runtime:add_entity(bounce_ball)
    runtime:add_entity(bounce_ball_b)

    bounce_walls = {
        create_bounce_wall("bounce_left", 80, 350, 20, 300, bounce_wall_material),
        create_bounce_wall("bounce_right", 560, 350, 20, 300, bounce_wall_material),
        create_bounce_wall("bounce_top", 320, 200, 500, 20, bounce_wall_material),
        create_bounce_wall("bounce_bottom", 320, 500, 500, 20, bounce_wall_material)
    }

    physics_world = PhysicsWorld.new(runtime.world, bounce_material_resolver)

    physics_world:add_entity(bounce_ball, { shape = "bounce" })
    physics_world:add_entity(bounce_ball_b, { shape = "bounce" })

    for _, wall in ipairs(bounce_walls) do
        physics_world:add_entity(wall, { shape = "bounce" })
    end
end

-- Processes player actions and advances the runtime every frame.
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

    if runtime:is_action_pressed("interact") then
        runtime:trigger_spatial_action("interact", player_entity)
    end

    physics_step:update(dt, update_physics)
    runtime:update(dt)
end

-- Draws the current test scene and diagnostic information.
function love.draw()
    love.graphics.print(table.concat(messages, "\n"), 20, 20)
    love.graphics.print("Active events: " .. runtime:get_active_event_count(), 20, 100)

    local velocity_a_x, velocity_a_y = bounce_velocity:get()
    local velocity_b_x, velocity_b_y = bounce_velocity_b:get()

    love.graphics.print(string.format("Ball A velocity: %.2f, %.2f", velocity_a_x, velocity_a_y), 20, 130)
    love.graphics.print(string.format("Ball B velocity: %.2f, %.2f", velocity_b_x, velocity_b_y), 20, 150)

    draw_shape(bounce_ball, "bounce")
    draw_shape(bounce_ball_b, "bounce")
    draw_forward(bounce_ball, 16)

    for _, wall in ipairs(bounce_walls) do
        draw_shape(wall, "bounce")
    end

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
