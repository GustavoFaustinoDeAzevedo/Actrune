local love = require "love"

local coreFolder = "engine/core/"
local Actrune = require(coreFolder .. "actrune")
local RateValue = require(coreFolder .. "values.rate_value")
local ActionActivation = require(coreFolder .. "actions.actions_activation")

local eventFolder = "engine/events/"
local Event = require(eventFolder .. "event")
local EventPage = require(eventFolder .. "event_page")
local DirectionalAreaTrigger = require(eventFolder .. "triggers.directional_area_trigger")

local commandFolder = "engine/events/commands/"
local CallCommand = require(commandFolder .. "call_command")
local WaitCommand = require(commandFolder .. "wait_command")

local engineFolder = "engine/world/"
local Entity = require(engineFolder .. "entity")

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
local player_movement_rate
local player_rotation_rate
local movement_activation
local rotation_activation
local runtime
local messages = {}


-- Adds a message to the test output.
local function add_message(message)
    table.insert(messages, message)
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

-- Creates the Actrune runtime and sets up the test entities and event.
function love.load()
    runtime = Actrune.new()
    runtime:bind_key("interact", "e")

    movement_activation = ActionActivation.new("down")
    rotation_activation = ActionActivation.new("down")

    -- runtime:bind_key("move_up", "w")
    -- runtime:bind_key("move_left", "a")
    -- runtime:bind_key("move_down", "s")
    -- runtime:bind_key("move_right", "d")
    -- runtime:bind_key("turn_left", "left")
    -- runtime:bind_key("turn_right", "right")

    -- Tank controls test
    runtime:bind_key("move_up", "w")
    runtime:bind_key("move_down", "s")
    runtime:bind_key("turn_left", "a")
    runtime:bind_key("turn_right", "d")

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
        rotation = math.rad(180),
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

    player_movement_rate = RateValue.new(120)

    player_rotation_rate = RateValue.new(
        math.rad(180)
    )

    player_direction = FacingDirection.new({ allow_strafe = false })

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
end

-- Processes player actions and updates the Actrune runtime every frame.
function love.update(dt)
    local move_x = 0
    local move_y = 0
    local turn_direction = 0

    if movement_activation:is_active(runtime, "move_up") then
        move_y = move_y - 1
    end

    if movement_activation:is_active(runtime, "move_down") then
        move_y = move_y + 1
    end

    if rotation_activation:is_active(runtime, "turn_left") then
        turn_direction = turn_direction - 1
    end

    if rotation_activation:is_active(runtime, "turn_right") then
        turn_direction = turn_direction + 1
    end

    local rotation_angle = turn_direction * player_rotation_rate:resolve(dt)
    player_rotation:turn(rotation_angle)

    local direction_x, direction_y =
        player_direction:resolve(
            move_x,
            move_y,
            player_entity.transform
        )

    local movement_distance = player_movement_rate:resolve(dt)

    player_translation:move(
        direction_x,
        direction_y,
        movement_distance
    )

    if runtime:is_action_pressed("interact") then
        runtime:trigger_spatial_action(
            "interact",
            player_entity
        )
    end

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
