local EventContext = require("engine.events.event_context")
local EventRunner = require("engine.events.event_runner")

local CallCommand = require("engine.events.commands.call_command")
local WaitCommand = require("engine.events.commands.wait_command")

local runner
local messages = {}

local function add_message(message)
    table.insert(messages, message)
end

function love.load()
    local context = EventContext.new({
        source = "test_event"
    })

    local commands = {
        CallCommand.new(function(ctx)
            add_message(
                "Evento iniciado por: " .. ctx.source
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

    runner = EventRunner.new(
        commands,
        context
    )
end

function love.update(dt)
    runner:update(dt)
end

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