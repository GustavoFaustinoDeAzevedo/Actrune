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

    test_entity = Entity.new({
        id = "test_entity",
        x = 120,
        y = 80
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

    local x, y = test_entity:get_position()
    love.graphics.circle(
        "fill",
        x,
        y,
        8
    )
end