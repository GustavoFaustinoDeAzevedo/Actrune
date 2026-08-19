local love = require "love"

local coreFolder = "engine/core/"
local Actrune = require(coreFolder .. "actrune")

local actionFolder = "engine/core/actions/"
local ActionAxis = require(actionFolder .. "action_axis")
local ActionActivation = require(actionFolder .. "actions_activation")
local ActionVector = require(actionFolder .. "action_vector")

local valueFolder = "engine/core/values/"
local Value = require(coreFolder .. "values.value")
local DeltaTimeValue = require(valueFolder .. "delta_time_value")
local ProductValue = require(valueFolder .. "product_value")

local eventFolder = "engine/events/"
local Event = require(eventFolder .. "event")
local EventPage = require(eventFolder .. "event_page")
local DirectionalAreaTrigger = require(eventFolder .. "triggers.directional_area_trigger")

local commandFolder = "engine/events/commands/"
local CallCommand = require(commandFolder .. "call_command")
local WaitCommand = require(commandFolder .. "wait_command")

local engineFolder = "engine/world/"
local Entity = require(engineFolder .. "entity")


local physicsFolder = "engine/world/physics/"
local PhysicalMaterial = require(physicsFolder .. "physical_material")
local ContactMaterialResolver = require(physicsFolder .. "contact_material_resolver")

local movementFolder = "engine/world/movement/"
local Velocity = require(movementFolder .. "velocity")
local Acceleration = require(movementFolder .. "acceleration")
local VelocityMotion = require(movementFolder .. "velocity_motion")
local VelocityResponse = require(movementFolder .. "velocity_response")

local spatialFolder = "engine/world/spatial/"
local PolygonShape = require(spatialFolder .. "polygon_shape")
local SpatialMover = require(spatialFolder .. "spatial_mover")

local translationFolder = "engine/world/movement/translation/"
local Translation = require(translationFolder .. "translation")

local directionFolder = "engine/world/movement/direction/"
local FacingDirection = require(directionFolder .. "facing_direction")

local rotationFolder = "engine/world/movement/rotation/"
local Rotation = require(rotationFolder .. "rotation")

local event_entity
local player_entity
local player_mover
local player_translation
local player_direction
local player_rotation
local player_rotation_amount
local player_turn_axis
local player_move_input
local player_velocity
local bounce_ball
local bounce_velocity
local bounce_mover
local bounce_acceleration
local bounce_ball_material
local bounce_wall_material
local bounce_material_resolver
local bounce_walls = {}
local runtime
local messages = {}


-- Adds a message to the test output.
local function add_message(message)
    table.insert(messages, message)
end

-- Reflects velocity using the effective properties of each material contact.
local function reflect_bounce_contacts(
    velocity,
    result
)
    for _, contact in ipairs(result.contacts) do
        local properties =
            bounce_material_resolver:resolve(
                contact.source_material,
                contact.target_material
            )

        VelocityResponse.reflect(
            velocity,
            contact.normal_x,
            contact.normal_y,
            properties.restitution
        )
    end
end

-- Removes velocity entering any contacted surface during the test.
local function remove_inward_contacts(
    velocity,
    result
)
    for _, contact in ipairs(
        result.contacts
    ) do
        VelocityResponse.remove_inward_component(
            velocity,
            contact.normal_x,
            contact.normal_y

        )
    end
end

-- Draws a named polygon shape belonging to an entity for debugging purposes.
local function draw_shape(entity, shape_name)
    local shape = entity:get_shape(shape_name)

    if shape == nil then
        return
    end

    local world_points =
        shape:get_world_points(entity.transform)

    love.graphics.polygon(
        "line",
        world_points
    )
end

-- Creates a rectangular collision wall with an optional physical material.
local function create_bounce_wall(
    id,
    x,
    y,
    width,
    height,
    material
)
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
                    {
                        x = -half_width,
                        y = -half_height
                    },
                    {
                        x = half_width,
                        y = -half_height
                    },
                    {
                        x = half_width,
                        y = half_height
                    },
                    {
                        x = -half_width,
                        y = half_height
                    }
                }
            })
        }
    })
end

-- Creates the Actrune runtime and sets up the test entities and event.
function love.load()
    runtime = Actrune.new()
    runtime:bind_key("interact", "space")

    bounce_ball_material =
        PhysicalMaterial.new({
            restitution = 0.8,
            static_friction = 0.6,
            dynamic_friction = 0.4
        })

    bounce_wall_material =
        PhysicalMaterial.new({
            restitution = 0.8,
            static_friction = 0.8,
            dynamic_friction = 0.8
        })

    bounce_material_resolver =
        ContactMaterialResolver.new({
            restitution_combiner = math.min,

            static_friction_combiner =
                function(a, b)
                    return math.sqrt(a * b)
                end,

            dynamic_friction_combiner =
                function(a, b)
                    return math.sqrt(a * b)
                end,

            default_restitution = 0,
            default_static_friction = 0,
            default_dynamic_friction = 0
        })

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

    -- runtime:bind_key("move_up", "w")
    -- runtime:bind_key("move_left", "a")
    -- runtime:bind_key("move_down", "s")
    -- runtime:bind_key("move_right", "d")
    -- runtime:bind_key("turn_left", "left")
    -- runtime:bind_key("turn_right", "right")

    -- Tank controls test
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

    bounce_ball = Entity.new({
        id = "bounce_ball",
        x = 320,
        y = 350,

        shapes = {
            bounce = PolygonShape.new({
                material = bounce_ball_material,

                points = {
                    { x = 0,   y = -10 },
                    { x = 7,   y = -7 },
                    { x = 10,  y = 0 },
                    { x = 7,   y = 7 },
                    { x = 0,   y = 10 },
                    { x = -7,  y = 7 },
                    { x = -10, y = 0 },
                    { x = -7,  y = -7 }
                }
            })
        }
    })

    runtime:add_entity(
        bounce_ball
    )

    bounce_velocity = Velocity.new({
        x = -2000,
        y = -1000
    })

    bounce_acceleration = Acceleration.new({
        x = 0,
        y = 980
    })

    bounce_mover = SpatialMover.new(
        runtime.world,
        bounce_ball,
        {
            source_shape = "bounce",
            target_shape = "bounce"
        }
    )

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

    player_rotation_amount = Value.new(math.rad(90))

    player_direction = FacingDirection.new()

    player_rotation = Rotation.new(
        player_entity.transform
    )

    player_mover = SpatialMover.new(
        runtime.world,
        player_entity,
        {
            source_shape = "collision",
            target_shape = "collision"
        }
    )

    player_translation = Translation.new(
        player_mover
    )

    local event = Event.new({
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
                    CallCommand.new(function()
                        add_message("Evento iniciado.")
                    end),

                    WaitCommand.new(2),

                    CallCommand.new(function()
                        add_message("Evento finalizado.")
                    end)
                }
            })
        }
    })

    event_entity:add_event(event)

    bounce_walls = {
        create_bounce_wall(
            "bounce_left",
            80,
            350,
            20,
            300,
            bounce_wall_material
        ),

        create_bounce_wall(
            "bounce_right",
            560,
            350,
            20,
            300,
            bounce_wall_material
        ),

        create_bounce_wall(
            "bounce_top",
            320,
            200,
            500,
            20,
            bounce_wall_material
        ),

        create_bounce_wall(
            "bounce_bottom",
            320,
            500,
            500,
            20,
            bounce_wall_material
        )
    }

    for _, wall in ipairs(bounce_walls) do
        runtime:add_entity(wall)
    end
end

-- Processes player actions and updates the Actrune runtime every frame.
function love.update(dt)
    local move_x, move_y =
        player_move_input:resolve(runtime)

    local turn_direction =
        player_turn_axis:resolve(runtime)

    local value_context = {
        dt = dt
    }

    local rotation_angle =
        turn_direction
        * player_rotation_amount:resolve(
            value_context
        )

    player_rotation:turn(
        rotation_angle
    )

    local direction_x, direction_y =
        player_direction:resolve(
            move_x,
            move_y,
            player_entity.transform
        )

    local movement_speed = 120

    player_velocity:set(
        direction_x * movement_speed,
        direction_y * movement_speed
    )

    local movement_x, movement_y =
        player_velocity:get_displacement(dt)

    player_translation:move(
        movement_x,
        movement_y
    )

    if runtime:is_action_pressed("interact") then
        runtime:trigger_spatial_action(
            "interact",
            player_entity
        )
    end

    local velocity_change_x, velocity_change_y =
        bounce_acceleration:get_velocity_change(dt)

    bounce_velocity:add(
        velocity_change_x,
        velocity_change_y
    )

    -- VelocityMotion.advance(
    --     bounce_mover,
    --     bounce_velocity,
    --     dt,
    --     reflect_bounce_contacts
    -- )

    VelocityMotion.advance(
        bounce_mover,
        bounce_velocity,
        dt,
        reflect_bounce_contacts
    )

    runtime:update(dt)
end

-- Draws the current event execution state for testing.
function love.draw()
    love.graphics.print(
        table.concat(messages, "\n"),
        20,
        20
    )

    love.graphics.print(
        "Active events: " .. runtime:get_active_event_count(),
        20,
        100
    )

    draw_shape(bounce_ball, "bounce")

    for _, wall in ipairs(bounce_walls) do
        draw_shape(wall, "bounce")
    end

    draw_shape(event_entity, "interaction")
    draw_shape(player_entity, "collision")
    draw_shape(event_entity, "collision")
end

-- Forwards keyboard press events from LÖVE to the Actrune runtime.
function love.keypressed(key)
    runtime:key_pressed(key)
end

-- Forwards keyboard release events from LÖVE to the Actrune runtime.
function love.keyreleased(key)
    runtime:key_released(key)
end
