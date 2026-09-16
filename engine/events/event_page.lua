---@class EventPage: EventPageFields
local EventPage = {}
EventPage.__index = EventPage

--- Checks the optional dense list before loading or copying a page.
---@param values any Authored map identifiers, or nil.
---@return string? message Validation failure, or nil when valid.
function EventPage.validate_required_maps(values)
    if values == nil then return nil end
    if type(values) ~= "table" then return "must be a list of map identifiers" end

    local count = 0
    for index in pairs(values) do
        if type(index) ~= "number" or index < 1 or index % 1 ~= 0 then
            return "must use consecutive positive integer indices"
        end
        count = count + 1
    end

    local seen = {}
    for index = 1, count do
        local id = values[index]
        if type(id) ~= "string" or id == "" then
            return "requires a non-empty map identifier at index " .. index
        end
        if seen[id] then return "duplicates map identifier '" .. id .. "'" end
        seen[id] = true
    end
    return nil
end

--- Creates a page and copies its declared map requirements.
--- Returned requirements are immutable for the lifetime of its runners.
---@param options EventPageOptions Page definition and runtime commands.
---@return EventPage page Independent page configuration.
function EventPage.new(options)
    assert(type(options) == "table", "options must be a table")
    assert(type(options.commands) == "table", "commands must be a table")
    assert(options.trigger ~= nil, "trigger is required")
    assert(options.condition == nil or type(options.condition) == "function",
        "condition must be a function")

    local map_error = EventPage.validate_required_maps(options.required_maps)
    assert(map_error == nil, "event page required_maps: " .. tostring(map_error))

    local required_maps = {}
    for index, id in ipairs(options.required_maps or {}) do required_maps[index] = id end

    return setmetatable({
        commands = options.commands,
        trigger = options.trigger,
        condition = options.condition,
        required_maps = required_maps
    }, EventPage)
end

--- Checks whether this page is currently available for a new execution.
---@param context table Event execution context.
---@return boolean available Whether the optional condition passes.
function EventPage:is_available(context)
    if self.condition == nil then return true end
    return self.condition(context)
end

--- Checks whether this page accepts the requested trigger.
---@param trigger_type string Requested action or signal.
---@param context table Event execution context.
---@return boolean matches Whether the configured trigger accepts this context.
function EventPage:matches_trigger(trigger_type, context)
    return self.trigger:matches(trigger_type, context)
end

return EventPage
