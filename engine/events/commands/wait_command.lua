local EventCommand = require("engine.events.event_command")

local WaitCommand = {}
WaitCommand.__index = WaitCommand

setmetatable(WaitCommand, {
    __index = EventCommand
})

function WaitCommand.new(duration)
    assert(
        type(duration) == "number",
        "duration must be a number"
    )

    assert(
        duration >= 0,
        "duration must be greater than or equal to zero"
    )

    local self = setmetatable(
        EventCommand.new(),
        WaitCommand
    )

    self.duration = duration

    return self
end

function WaitCommand:execute(context, state, dt)
    state.elapsed = (state.elapsed or 0) + dt

    if state.elapsed >= self.duration then
        return EventCommand.DONE
    end

    return EventCommand.RUNNING
end

return WaitCommand