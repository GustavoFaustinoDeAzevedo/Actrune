local EventContext = {}
EventContext.__index = EventContext

function EventContext.new(options)
    options = options or {}

    local self = setmetatable({}, EventContext)

    self.source = options.source
    self.world = options.world

    return self
end

return EventContext