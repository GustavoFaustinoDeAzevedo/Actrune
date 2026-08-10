local Actrune = require("engine.core.actrune")

local eventFolder = "engine/events/"
local Event = require(eventFolder .. "event")
local EventPage = require(eventFolder .. "event_page")
local EventContext = require(eventFolder .. "event_context")
local EventTrigger = require(eventFolder .. "event_trigger")

local commandFolder = "engine/events/commands/"
local CallCommand = require(commandFolder .. "call_command")
local WaitCommand = require(commandFolder .. "wait_command")

local Entity = require("engine.world.entity")
local PolygonShape = require("engine.world.spatial.polygon_shape")

local test_entity
local runtime
local messages = {}

-- Adds a message to the test output.
local function add_message(message)
    table.insert(messages, message)
end

-- Creates the Actrune runtime and starts the test event.
function love.load()
    runtime = Actrune.new() 

    local event = Event.new({
        id = "test_event",

        pages = {
            EventPage.new({
                trigger = EventTrigger.new("interact"),

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

    local context = EventContext.new({
        source = event
    })

    runtime:trigger_event(
        event,
        "interact",
        context
    )

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
    test_entity = Entity.new({
        id = "test_entity",
        x = 200,
        y = 150,
        rotation = math.rad(30),
        scale_x = 1.5,
        scale_y = 1,

        shape = PolygonShape.new({
            points = {
                { x = -30, y = -20 },
                { x = 30, y = -20 },
                { x = 40, y = 20 },
                { x = 0, y = 40 },
                { x = -40, y = 20 }
            }
        })
    })
end

-- Updates the Actrune runtime every frame.
function love.update(dt)
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

    local shape = test_entity:get_shape()

    if shape then
        local world_points =
            shape:get_world_points(test_entity.transform)

        love.graphics.polygon(
            "line",
            world_points
        )
    end
end