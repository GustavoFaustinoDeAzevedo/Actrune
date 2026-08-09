local EventCommand = {}
EventCommand.__index = EventCommand

EventCommand.RUNNING = "running"
EventCommand.DONE = "done"

function EventCommand.new()
    return setmetatable({}, EventCommand)
end

function EventCommand:execute(context, state, dt)
    error("EventCommand:execute() must be implemented")
end

return EventCommand