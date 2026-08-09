local eventFolder = "engine/events/"
local Event = require(eventFolder .. "event")
local EventPage = require(eventFolder .. "event_page")
local EventCommand = require(eventFolder .. "event_command")
local EventContext = require(eventFolder .. "event_context")
local EventTrigger = require(eventFolder .. "event_trigger")

local commandFolder = "engine/events/commands/"
local CallCommand = require(commandFolder .. "call_command")
local WaitCommand = require(commandFolder .. "wait_command")


local runner
local messages = {}

local function add_message(message)
    table.insert(messages, message)
end

-- Creates the test event and starts its execution.
function love.load()
    local event = Event.new({
        id = "test_event",

        pages = {
            EventPage.new({
                trigger = EventTrigger.new("interact"),

                commands = {
                    CallCommand.new(function()
                        add_message("Evento executado.")
                    end)
                }
            })
        }
    })

    local context = EventContext.new({
        source = event,

        variables = {
            special = false
        }
    })

    runner = event:trigger("interact", context)
end

-- Adds a message to the debug message list.
local function add_message(message)
    table.insert(messages, message)
end

-- Advances the active event runner every frame.
function love.update(dt)
    if runner then
        runner:update(dt)
    end
end

-- Draws the event execution state on the screen.
function love.draw()
    love.graphics.print(
        table.concat(messages, "\n"),
        20,
        20
    )

    if runner and runner:is_finished() then
        love.graphics.print(
            "Evento finalizado.",
            20,
            120
        )
    end
end