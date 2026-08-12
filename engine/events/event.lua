local EventRunner = require("engine.events.event_runner")

local Event = {}
Event.__index = Event

-- Creates a new event definition with an identifier, event pages, and execution mode.
function Event.new(options)
    assert(type(options) == "table", "options must be a table")
    assert(type(options.id) == "string", "event id must be a string")
    assert(type(options.pages) == "table", "pages must be a table")

    local execution_mode = options.execution_mode or "parallel"

    assert(
        execution_mode == "parallel"
        or execution_mode == "single",
        "invalid event execution mode: " .. execution_mode
    )

    local self = setmetatable({}, Event)

    self.id = options.id
    self.pages = options.pages
    self.execution_mode = execution_mode

    return self
end

-- Returns the highest-priority page whose condition is currently satisfied.
function Event:get_active_page(context)
    for index = #self.pages, 1, -1 do
        local page = self.pages[index]

        if page:is_available(context) then
            return page
        end
    end

    return nil
end

-- Creates an independent runner for this event using the given context.
function Event:create_runner(context)
    return EventRunner.new(self, context)
end

-- Attempts to start this event using the requested trigger type.
function Event:trigger(trigger_type, context)
    local page = self:get_active_page(context)

    if page == nil then
        return nil
    end

    if not page:matches_trigger(trigger_type, context) then
        return nil
    end

    return self:create_runner(context)
end

return Event