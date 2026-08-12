local World = require("engine.world.world")
local Input = require("engine.core.input")
local EventContext = require("engine.events.event_context")
local EventScheduler = require("engine.events.event_scheduler")

local Actrune = {}
Actrune.__index = Actrune
Actrune.VERSION = "0.2.0"

-- Creates a new Actrune runtime with its world, input manager, and event scheduler.
function Actrune.new()
    local self = setmetatable({}, Actrune)

    self.world = World.new()
    self.input = Input.new()
    self.event_scheduler = EventScheduler.new()
    self.spatial_actions = {}

    return self
end

-- Updates all runtime systems and clears transient input states after the frame.
function Actrune:update(dt)
    self.event_scheduler:update(dt)

    self.input:end_frame()
end

-- Attempts to trigger an event while respecting its execution mode.
function Actrune:trigger_event(event, trigger_type, context)
    if
        event.execution_mode == "single"
        and self.event_scheduler:is_event_running(event)
    then
        return nil
    end

    local runner = event:trigger(trigger_type, context)

    self.event_scheduler:add(runner)

    return runner
end

-- Attempts to trigger all events associated with an entity.
function Actrune:trigger_entity_events(entity, trigger_type, activator)
    assert(entity ~= nil, "entity is required")

    local runners = {}

    for _, event in pairs(entity:get_events()) do
        local context = EventContext.new({
            source = event,
            entity = entity,
            activator = activator,
            world = self.world
        })

        local runner = self:trigger_event(
            event,
            trigger_type,
            context
        )

        if runner then
            table.insert(runners, runner)
        end
    end

    return runners
end

-- Finds entities at a world-space point and attempts to trigger their events.
function Actrune:trigger_events_at_point(
    x,
    y,
    shape_name,
    trigger_type,
    activator
)
    local entities = self.world:query_point(
        x,
        y,
        shape_name
    )

    local runners = {}

    for _, entity in ipairs(entities) do
        local entity_runners =
            self:trigger_entity_events(
                entity,
                trigger_type,
                activator
            )

        for _, runner in ipairs(entity_runners) do
            table.insert(runners, runner)
        end
    end

    return runners
end

-- Finds entities overlapping an activator shape and attempts to trigger their events.
function Actrune:trigger_events_with_shape(
    activator,
    activator_shape_name,
    target_shape_name,
    trigger_type
)
    assert(activator ~= nil, "activator is required")
    assert(
        type(activator_shape_name) == "string",
        "activator shape name must be a string"
    )
    assert(
        type(target_shape_name) == "string",
        "target shape name must be a string"
    )

    local activator_shape =
        activator:get_shape(activator_shape_name)

    if activator_shape == nil then
        return {}
    end

    local entities = self.world:query_shape(
        activator_shape,
        activator.transform,
        target_shape_name
    )

    local runners = {}

    for _, entity in ipairs(entities) do
        if entity ~= activator then
            local entity_runners =
                self:trigger_entity_events(
                    entity,
                    trigger_type,
                    activator
                )

            for _, runner in ipairs(entity_runners) do
                table.insert(runners, runner)
            end
        end
    end

    return runners
end

-- Returns the number of event executions currently active.
function Actrune:get_active_event_count()
    return self.event_scheduler:get_active_count()
end

-- Adds an entity to the world managed by this runtime.
function Actrune:add_entity(entity)
    self.world:add_entity(entity)
end

-- Returns an entity from the world by its identifier.
function Actrune:get_entity(id)
    return self.world:get_entity(id)
end

-- Binds a keyboard key to an input action.
function Actrune:bind_key(action, key)
    self.input:bind_key(action, key)
end

-- Records a keyboard press in the input system.
function Actrune:key_pressed(key)
    self.input:key_pressed(key)
end

-- Records a keyboard release in the input system.
function Actrune:key_released(key)
    self.input:key_released(key)
end

-- Checks whether an input action was pressed during the current frame.
function Actrune:is_action_pressed(action)
    return self.input:is_action_pressed(action)
end

-- Checks whether an input action is currently being held down.
function Actrune:is_action_down(action)
    return self.input:is_action_down(action)
end

-- Checks whether an input action was released during the current frame.
function Actrune:is_action_released(action)
    return self.input:is_action_released(action)
end

-- Registers a reusable spatial event action with its shape and trigger configuration.
function Actrune:bind_spatial_action(action, options)
    assert(type(action) == "string", "action must be a string")
    assert(type(options) == "table", "options must be a table")
    assert(
        type(options.activator_shape) == "string",
        "activator shape must be a string"
    )
    assert(
        type(options.target_shape) == "string",
        "target shape must be a string"
    )
    assert(
        type(options.trigger) == "string",
        "trigger must be a string"
    )

    self.spatial_actions[action] = {
        activator_shape = options.activator_shape,
        target_shape = options.target_shape,
        trigger = options.trigger
    }
end

-- Triggers a registered spatial action using the given entity as its activator.
function Actrune:trigger_spatial_action(action, activator)
    local spatial_action = self.spatial_actions[action]

    if spatial_action == nil then
        return {}
    end

    return self:trigger_events_with_shape(
        activator,
        spatial_action.activator_shape,
        spatial_action.target_shape,
        spatial_action.trigger
    )
end

return Actrune