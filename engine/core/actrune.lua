local World = require("engine.world.world")
local EventContext = require("engine.events.event_context")
local EventScheduler = require("engine.events.event_scheduler")


local Actrune = {}
Actrune.__index = Actrune

-- Creates a new Actrune runtime with its world and event scheduler.
function Actrune.new()
    local self = setmetatable({}, Actrune)

    self.world = World.new()
    self.event_scheduler = EventScheduler.new()

    return self
end

-- Updates all systems currently managed by the Actrune runtime.
function Actrune:update(dt)
    self.event_scheduler:update(dt)
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



return Actrune