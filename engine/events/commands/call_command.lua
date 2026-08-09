local EventCommand = require("engine.events.event_command")

local CallCommand = {}
CallCommand.__index = CallCommand

setmetatable(CallCommand, {
    __index = EventCommand
})

function CallCommand.new(callback)
    assert(
        type(callback) == "function",
        "callback must be a function"
    )

    local self = setmetatable(
        EventCommand.new(),
        CallCommand
    )

    self.callback = callback

    return self
end

function CallCommand:execute(context, state, dt)
    if not state.called then
        self.callback(context)
        state.called = true
    end

    return EventCommand.DONE
end

return CallCommand