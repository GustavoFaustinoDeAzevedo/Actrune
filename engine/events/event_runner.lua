local EventCommand = require("engine.events.event_command")

local EventRunner = {}
EventRunner.__index = EventRunner

function EventRunner.new(commands, context)
    assert(type(commands) == "table", "commands must be a table")
    assert(context ~= nil, "context is required")

    local self = setmetatable({}, EventRunner)

    self.commands = commands
    self.context = context

    self.current_index = 1
    self.current_state = nil

    self.finished = #commands == 0

    return self
end

function EventRunner:update(dt)
    if self.finished then
        return
    end

    while not self.finished do
        local command = self.commands[self.current_index]

        if command == nil then
            self.finished = true
            return
        end

        if self.current_state == nil then
            self.current_state = {}
        end

        local status = command:execute(
            self.context,
            self.current_state,
            dt
        )

        if status == EventCommand.DONE then
            self.current_index = self.current_index + 1
            self.current_state = nil

        elseif status == EventCommand.RUNNING then
            return

        else
            error(
                "Invalid command status: "
                .. tostring(status)
            )
        end
    end
end

function EventRunner:is_finished()
    return self.finished
end

return EventRunner