local EventScheduler = require("engine.events.event_scheduler")

local Actrune = {}
Actrune.__index = Actrune

-- Creates a new Actrune runtime with its event scheduler.
function Actrune.new()
    local self = setmetatable({}, Actrune)

    self.event_scheduler = EventScheduler.new()

    return self
end

-- Updates all systems currently managed by the Actrune runtime.
function Actrune:update(dt)
    self.event_scheduler:update(dt)
end

-- Attempts to trigger an event and schedules its runner when successful.
function Actrune:trigger_event(event, trigger_type, context)
    local runner = event:trigger(trigger_type, context)

    self.event_scheduler:add(runner)

    return runner
end

-- Returns the number of event executions currently active.
function Actrune:get_active_event_count()
    return self.event_scheduler:get_active_count()
end

return Actrune