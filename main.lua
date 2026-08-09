local EventContext = require("engine.events.event_context")
local EventRunner = require("engine.events.event_runner")

local CallCommand = require("engine.events.commands.call_command")
local WaitCommand = require("engine.events.commands.wait_command")
local Event = require("engine.events.event")

local runner
local messages = {}

local function add_message(message)
    table.insert(messages, message)
end

-- Creates the test event and starts its execution.
function love.load()
    local event = Event.new({
        id = "test_event",

        commands = {
            CallCommand.new(function(ctx)
                add_message(
                    "Evento iniciado por: " .. ctx.source.id
                )
            end),

            WaitCommand.new(2),

            CallCommand.new(function()
                add_message("Passaram 2 segundos.")
            end),

            WaitCommand.new(1),

            CallCommand.new(function()
                add_message("Passou mais 1 segundo.")
            end)
        }
    })

    local context = EventContext.new({
        source = event
    })

    runner = EventRunner.new(
        event,
        context
    )
end

-- Adds a message to the debug message list.
local function add_message(message)
    table.insert(messages, message)
end

-- Advances the active event runner every frame.
function love.update(dt)
    runner:update(dt)
end

-- Draws the event execution state on the screen.
function love.draw()
    love.graphics.print(
        table.concat(messages, "\n"),
        20,
        20
    )

    if runner:is_finished() then
        love.graphics.print(
            "Evento finalizado.",
            20,
            120
        )
    end
end