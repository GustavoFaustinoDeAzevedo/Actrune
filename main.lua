local Event = require("engine.events.event")
local EventPage = require("engine.events.event_page")
local EventContext = require("engine.events.event_context")

local CallCommand = require("engine.events.commands.call_command")
local WaitCommand = require("engine.events.commands.wait_command")

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
                commands = {
                    CallCommand.new(function()
                        add_message("Página padrão.")
                    end)
                }
            }),

            EventPage.new({
                condition = function(ctx)
                    return ctx.variables.special == true
                end,

                commands = {
                    CallCommand.new(function()
                        add_message("Página especial.")
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

    runner = event:create_runner(context)
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