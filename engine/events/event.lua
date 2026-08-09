local EventRunner = require("engine.events.event_runner")

local Event = {}
Event.__index = Event

-- Creates a new event definition with an identifier and command list.
function Event.new(options)
    assert(type(options) == "table", "options must be a table")
    assert(type(options.id) == "string", "event id must be a string")
    assert(type(options.commands) == "table", "commands must be a table")

    local self = setmetatable({}, Event)

    self.id = options.id
    self.commands = options.commands

    return self
end

-- Creates an independent runner for this event using the given context.
function Event:create_runner(context)
    return EventRunner.new(self, context)
end

return Event