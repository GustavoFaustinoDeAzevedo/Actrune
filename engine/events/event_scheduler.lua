local EventScheduler = {}
EventScheduler.__index = EventScheduler

-- Creates a scheduler responsible for managing active event runners.
function EventScheduler.new()
    local self = setmetatable({}, EventScheduler)

    self.runners = {}

    return self
end

-- Adds an event runner to the scheduler if it exists.
function EventScheduler:add(runner)
    if runner == nil then
        return
    end

    table.insert(self.runners, runner)
end

-- Updates all active runners and removes the ones that have finished.
function EventScheduler:update(dt)
    for index = #self.runners, 1, -1 do
        local runner = self.runners[index]

        runner:update(dt)

        if runner:is_finished() then
            table.remove(self.runners, index)
        end
    end
end

-- Returns the number of event runners currently being executed.
function EventScheduler:get_active_count()
    return #self.runners
end

-- Checks whether the given event currently has an active runner.
function EventScheduler:is_event_running(event)
    for _, runner in ipairs(self.runners) do
        if runner.event == event then
            return true
        end
    end

    return false
end

return EventScheduler