local EventTrigger = {}
EventTrigger.__index = EventTrigger

-- Creates a new trigger identified by a unique trigger type.
function EventTrigger.new(trigger_type)
    assert(
        type(trigger_type) == "string",
        "trigger type must be a string"
    )

    local self = setmetatable({}, EventTrigger)

    self.type = trigger_type

    return self
end

-- Checks whether this trigger matches the requested trigger type.
function EventTrigger:matches(trigger_type, context)
    return self.type == trigger_type
end

return EventTrigger