local EventTrigger = require("engine.events.event_trigger")
local SpatialQuery = require("engine.world.spatial.spatial_query")

local AreaTrigger = {}
AreaTrigger.__index = AreaTrigger

setmetatable(AreaTrigger, {
    __index = EventTrigger
})

-- Creates an area trigger using a target shape and an optional activator shape.
function AreaTrigger.new(options)
    assert(type(options) == "table", "options must be a table")
    assert(type(options.type) == "string", "trigger type must be a string")
    assert(type(options.shape) == "string", "shape name must be a string")

    if options.activator_shape ~= nil then
        assert(
            type(options.activator_shape) == "string",
            "activator shape name must be a string"
        )
    end

    local self = setmetatable(
        EventTrigger.new(options.type),
        AreaTrigger
    )

    self.shape_name = options.shape
    self.activator_shape_name = options.activator_shape

    return self
end

-- Checks whether the trigger matches and the activator overlaps the configured area.
function AreaTrigger:matches(trigger_type, context)
    if self.type ~= trigger_type then
        return false
    end

    if context.entity == nil or context.activator == nil then
        return false
    end

    local target_shape =
        context.entity:get_shape(self.shape_name)

    if target_shape == nil then
        return false
    end

    if self.activator_shape_name then
        local activator_shape =
            context.activator:get_shape(
                self.activator_shape_name
            )

        if activator_shape == nil then
            return false
        end

        return SpatialQuery.polygons_intersect(
            target_shape,
            context.entity.transform,
            activator_shape,
            context.activator.transform
        )
    end

    local x, y = context.activator:get_position()

    return target_shape:contains_point(
        x,
        y,
        context.entity.transform
    )
end

return AreaTrigger