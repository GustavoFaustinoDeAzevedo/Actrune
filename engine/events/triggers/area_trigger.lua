local EventTrigger = require("engine.events.event_trigger")
local SpatialQuery = require("engine.world.spatial.spatial_query")

local AreaTrigger = {}
AreaTrigger.__index = AreaTrigger

setmetatable(AreaTrigger, {
    __index = EventTrigger
})

-- Creates an area trigger with an explicit vertical interaction policy.
function AreaTrigger.new(options)
    assert(type(options) == "table", "options must be a table")
    assert(type(options.type) == "string", "trigger type must be a string")
    assert(type(options.shape) == "string", "shape name must be a string")
    assert(options.activator_shape == nil or type(options.activator_shape) == "string",
        "activator shape name must be a string")
    assert(options.vertical_mode == "overlap" or options.vertical_mode == "ignore",
        "area trigger requires vertical_mode overlap or ignore")
    assert(options.enabled == nil or type(options.enabled) == "boolean",
        "area trigger enabled must be a boolean")

    if options.vertical_mode == "overlap" then
        assert(type(options.target_vertical_range) == "string"
            and options.target_vertical_range ~= "",
            "area trigger requires a target vertical range component")
        assert(type(options.activator_vertical_range) == "string"
            and options.activator_vertical_range ~= "",
            "area trigger requires an activator vertical range component")
    end

    local self = setmetatable(EventTrigger.new(options.type), AreaTrigger)

    self.shape_name = options.shape
    self.enabled = options.enabled ~= false
    self.activator_shape_name = options.activator_shape
    self.vertical_mode = options.vertical_mode
    self.target_vertical_range = options.target_vertical_range
    self.activator_vertical_range = options.activator_vertical_range

    return self
end

-- Checks vertical reach before running horizontal geometry tests.
function AreaTrigger:_matches_vertical(context)
    if self.vertical_mode == "ignore" then return true end

    local target = context.entity:get_component(self.target_vertical_range)
    local activator = context.activator:get_component(self.activator_vertical_range)

    -- Entities without the requested interaction capability cannot match this trigger.
    if target == nil or activator == nil then return false end

    assert(type(target.get_bounds) == "function",
        "target vertical range must expose get_bounds")
    assert(type(activator.get_bounds) == "function",
        "activator vertical range must expose get_bounds")

    local target_min, target_max = target:get_bounds(context.entity)
    local activator_min, activator_max = activator:get_bounds(context.activator)

    -- Touching interval endpoints count as reachable.
    return activator_max >= target_min and target_max >= activator_min
end

-- Checks action, vertical reach, and horizontal area overlap.
function AreaTrigger:matches(trigger_type, context)
    if not self.enabled then return false end
    if self.type ~= trigger_type then return false end
    if context.entity == nil or context.activator == nil then return false end
    if not self:_matches_vertical(context) then return false end

    local target_shape = context.entity:get_shape(self.shape_name)
    if target_shape == nil then return false end

    if self.activator_shape_name ~= nil then
        local activator_shape = context.activator:get_shape(self.activator_shape_name)
        if activator_shape == nil then return false end

        return SpatialQuery.polygons_intersect(
            target_shape,
            context.entity.transform,
            activator_shape,
            context.activator.transform
        )
    end

    local x, y = context.activator:get_position()
    return target_shape:contains_point(x, y, context.entity.transform)
end

-- Enables or blocks future matches without changing the interaction rules.
function AreaTrigger:set_enabled(enabled)
    assert(type(enabled) == "boolean", "area trigger enabled must be a boolean")
    self.enabled = enabled
end

return AreaTrigger
