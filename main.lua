local Actrune = require("engine.core.actrune")

local eventFolder = "engine/events/"
local Event = require(eventFolder .. "event")
local EventPage = require(eventFolder .. "event_page")
local DirectionalAreaTrigger = require("engine.events.triggers.directional_area_trigger")

local commandFolder = "engine/events/commands/"
local CallCommand = require(commandFolder .. "call_command")
local WaitCommand = require(commandFolder .. "wait_command")

local engineFolder = "engine/world/"
local Entity = require(engineFolder .. "entity")


local movementFolder = "engine/world/movement/"
local FreeMovement = require( movementFolder .. "free_movement")

local spatialFolder = "engine/world/spatial/"
local PolygonShape = require(spatialFolder .. "polygon_shape")
local SpatialMover = require(spatialFolder .. "spatial_mover")

local event_entity
local player_entity
local player_mover
local player_movement
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
    runtime:bind_key("move_up", "w")
    runtime:bind_key("move_left", "a")
    runtime:bind_key("move_down", "s")
    runtime:bind_key("move_right", "d")    
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
                    { x = 50, y = -40 },
                    { x = 50, y = 40 },
                    { x = -50, y = 40 }
                }
            }),

            collision = PolygonShape.new({
                points = {
                    { x = -20, y = -40 },
                    { x = 20, y = -40 },
                    { x = 20, y = 40 },
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
                    { x = 15, y = -15 },
                    { x = 15, y = 15 },
                    { x = -15, y = 15 }
                }
            })
        }
    })

    runtime:add_entity(event_entity)
    runtime:add_entity(player_entity)

    player_mover = SpatialMover.new(
    runtime.world,
    player_entity,
        {
            source_shape = "collision",
            target_shape = "collision"
        }
    )

    player_movement = FreeMovement.new(
    player_mover,
        {
            speed = 120
        }
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

    if runtime:is_action_down("move_left") then
        move_x = move_x - 1
    end

    if runtime:is_action_down("move_right") then
        move_x = move_x + 1
    end

    if runtime:is_action_down("move_up") then
        move_y = move_y - 1
    end

    if runtime:is_action_down("move_down") then
        move_y = move_y + 1
    end

    player_movement:move(
        move_x,
        move_y,
        dt
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