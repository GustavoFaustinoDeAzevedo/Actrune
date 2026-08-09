local EventPage = {}
EventPage.__index = EventPage

-- Creates a new event page with commands and an optional activation condition.
function EventPage.new(options)
    assert(type(options) == "table", "options must be a table")
    assert(type(options.commands) == "table", "commands must be a table")

    if options.condition ~= nil then
        assert(
            type(options.condition) == "function",
            "condition must be a function"
        )
    end

    local self = setmetatable({}, EventPage)

    self.commands = options.commands
    self.condition = options.condition

    return self
end

-- Checks whether this page can be active in the given context.
function EventPage:is_available(context)
    if self.condition == nil then
        return true
    end

    return self.condition(context)
end

return EventPage