local eventFolder = "engine/events/"
local Event = require(eventFolder .. "event")
local EventPage = require(eventFolder .. "event_page")
local EventCommand = require(eventFolder .. "event_command")
local EventContext = require(eventFolder .. "event_context")
local EventTrigger = require(eventFolder .. "event_trigger")
local EventScheduler = require(eventFolder .. "event_scheduler")

local commandFolder = "engine/events/commands/"
local CallCommand = require(commandFolder .. "call_command")
local WaitCommand = require(commandFolder .. "wait_command")


local scheduler
local messages = {}

local function add_message(message)
    table.insert(messages, message)
end

-- Creates the test event and schedules it when its trigger matches.
function love.load()
    scheduler = EventScheduler.new()

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
                        add_message("Evento finalizado após a espera.")
                    end)
                }
            })
        }
    })

    local context = EventContext.new({
        source = event
    })

    scheduler:add(
        event:trigger("interact", context)
    )

    scheduler:add(
        event:trigger("interact", context)
    )
end

-- Adds a message to the debug message list.
local function add_message(message)
    table.insert(messages, message)
end

-- Updates all event executions managed by the scheduler.
function love.update(dt)
    scheduler:update(dt)
end

-- Draws the test messages and the number of active event executions.
function love.draw()
    love.graphics.print(
        table.concat(messages, "\n"),
        20,
        20
    )

    love.graphics.print(
        "Active runners: " .. scheduler:get_active_count(),
        20,
        100
    )
end