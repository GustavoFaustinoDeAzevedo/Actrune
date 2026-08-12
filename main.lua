local Actrune = require("engine.core.actrune")

local eventFolder = "engine/events/"
local Event = require(eventFolder .. "event")
local EventPage = require(eventFolder .. "event_page")
local DirectionalAreaTrigger = require("engine.events.triggers.directional_area_trigger")

local commandFolder = "engine/events/commands/"
local CallCommand = require(commandFolder .. "call_command")
local WaitCommand = require(commandFolder .. "wait_command")

local Entity = require("engine.world.entity")
local PolygonShape = require("engine.world.spatial.polygon_shape")

local event_entity
local player_entity
local test_entity
local runtime
local messages = {}


-- Adds a message to the test output.
local function add_message(message)
    table.insert(messages, message)
end

-- Creates the Actrune runtime and sets up the test entities and event.
function love.load()
    runtime = Actrune.new() 
    runtime:bind_key("interact", "e")
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

    -- test_entity = Entity.new({
    --     id = "test_entity",
    --     x = 120,
    --     y = 80,

    --     shape = PolygonShape.new({
    --         points = {
    --             { x = -30, y = -20 },
    --             { x = 30, y = -20 },
    --             { x = 40, y = 20 },
    --             { x = 0, y = 40 },
    --             { x = -40, y = 20 }
    --         }
    --     })
    -- })
    print(runtime:get_entity("player").id)
    test_entity = Entity.new({
        id = "test_entity",
        x = 200,
        y = 150,
        rotation = math.rad(30),

        shapes = {
            interaction = PolygonShape.new({
                points = {
                    { x = -30, y = -20 },
                    { x = 30, y = -20 },
                    { x = 40, y = 20 },
                    { x = 0, y = 40 },
                    { x = -40, y = 20 }
                }
            })
        }
    })    
end

-- Processes game actions and updates the Actrune runtime every frame.
function love.update(dt)
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

    local shape = test_entity:get_shape("interaction")

    if shape then
        local world_points =
            shape:get_world_points(test_entity.transform)

        love.graphics.polygon(
            "line",
            world_points
        )

        local mouse_x, mouse_y = love.mouse.getPosition()

        if shape:contains_point(
            mouse_x,
            mouse_y,
            test_entity.transform
        ) then
            love.graphics.print(
                "Mouse inside shape",
                20,
                140
            )
        else
            love.graphics.print(
                "" ,
                20,
                140
            )
        end
    end
end

-- Forwards keyboard press events from LÖVE to the Actrune runtime.
function love.keypressed(key)
    runtime:key_pressed(key)
end

-- Forwards keyboard release events from LÖVE to the Actrune runtime.
function love.keyreleased(key)
    runtime:key_released(key)
end