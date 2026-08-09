local EventRunner = require("engine.events.event_runner")

local Event = {}
Event.__index = Event

-- Creates a new event definition with an identifier and event pages.
function Event.new(options)
    assert(type(options) == "table", "options must be a table")
    assert(type(options.id) == "string", "event id must be a string")
    assert(type(options.pages) == "table", "pages must be a table")

    local self = setmetatable({}, Event)

    self.id = options.id
    self.pages = options.pages

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

return Event