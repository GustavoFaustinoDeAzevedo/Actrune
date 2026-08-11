local AreaTrigger = require("engine.events.triggers.area_trigger")

local DirectionalAreaTrigger = {}
DirectionalAreaTrigger.__index = DirectionalAreaTrigger

setmetatable(DirectionalAreaTrigger, {
    __index = AreaTrigger
})

-- Creates an area trigger that also requires the activator to face the target entity.
function DirectionalAreaTrigger.new(options)
    assert(type(options) == "table", "options must be a table")

    local self = setmetatable(
        AreaTrigger.new(options),
        DirectionalAreaTrigger
    )

    self.max_angle = options.max_angle or math.rad(60)

    return self
end

-- Checks whether the activator overlaps the area and is facing the target entity.
function DirectionalAreaTrigger:matches(trigger_type, context)
    if not AreaTrigger.matches(self, trigger_type, context) then
        return false
    end

    local activator_x, activator_y =
        context.activator:get_position()

    local target_x, target_y =
        context.entity:get_position()

    local direction_x = target_x - activator_x
    local direction_y = target_y - activator_y

    local distance = math.sqrt(
        direction_x * direction_x
        + direction_y * direction_y
    )

    if distance == 0 then
        return true
    end

    direction_x = direction_x / distance
    direction_y = direction_y / distance

    local forward_x, forward_y =
        context.activator.transform:get_forward()

    local dot =
        forward_x * direction_x
        + forward_y * direction_y

    local minimum_dot = math.cos(self.max_angle)

    return dot >= minimum_dot
end

return DirectionalAreaTrigger