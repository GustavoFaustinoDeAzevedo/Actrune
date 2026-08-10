local EventContext = {}
EventContext.__index = EventContext

-- Creates a new execution context containing data shared with events and commands.
function EventContext.new(options)
    options = options or {}

    local self = setmetatable({}, EventContext)

    self.source = options.source
    self.entity = options.entity
    self.activator = options.activator
    self.world = options.world
    self.variables = options.variables or {}

    return self
end

return EventContext