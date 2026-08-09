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

return Event