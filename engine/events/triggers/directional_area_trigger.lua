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

--- Requires facing the same target image that passed the area overlap test.
---@param trigger_type string Requested action type.
---@param context table Event context containing entity, activator and optional world.
---@return boolean matches Whether an overlapping target image is inside the facing angle.
function DirectionalAreaTrigger:matches(trigger_type, context)
    if context.entity == nil or context.activator == nil then return false end

    local activator_x, activator_y = context.activator:get_position()
    local target_x, target_y = context.entity:get_position()
    local forward_x, forward_y = context.activator.transform:get_forward()
    local minimum_dot = math.cos(self.max_angle)

    return AreaTrigger.matches(self, trigger_type, context, function(offset_x, offset_y)
        local dx, dy = target_x + offset_x - activator_x, target_y + offset_y - activator_y
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance == 0 then return true end
        return (forward_x * dx + forward_y * dy) / distance >= minimum_dot
    end)
end

return DirectionalAreaTrigger
