local EventTrigger = require("engine.events.event_trigger")

local AreaTrigger = {}
AreaTrigger.__index = AreaTrigger

setmetatable(AreaTrigger, {
    __index = EventTrigger
})

-- Creates a trigger that requires the activator to be inside a named entity shape.
function AreaTrigger.new(options)
    assert(type(options) == "table", "options must be a table")
    assert(type(options.type) == "string", "trigger type must be a string")
    assert(type(options.shape) == "string", "shape name must be a string")

    local self = setmetatable(
        EventTrigger.new(options.type),
        AreaTrigger
    )

    self.shape_name = options.shape

    return self
end

-- Checks whether the trigger type matches and the activator is inside the configured shape.
function AreaTrigger:matches(trigger_type, context)
    if self.type ~= trigger_type then
        return false
    end

    if context.entity == nil or context.activator == nil then
        return false
    end

    local shape = context.entity:get_shape(self.shape_name)

    if shape == nil then
        return false
    end

    local x, y = context.activator:get_position()

    return shape:contains_point(
        x,
        y,
        context.entity.transform
    )
end

return AreaTrigger