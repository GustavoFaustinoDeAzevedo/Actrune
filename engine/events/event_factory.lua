local Event = require("engine.events.event")
local EventPage = require("engine.events.event_page")

local EventFactory = {}
EventFactory.__index = EventFactory

-- Creates an event factory backed by an extensible project type catalog.
function EventFactory.new(type_catalog)
  local self = setmetatable({}, EventFactory)

  self.type_catalog = type_catalog
  self.actions = {}

  assert(self.type_catalog ~= nil, "event factory requires a type catalog")
  assert(self.type_catalog:has_registry("trigger"), "event factory requires a trigger registry")
  assert(self.type_catalog:has_registry("command"), "event factory requires a command registry")

  return self
end

-- Registers a serializable trigger type in the current project type catalog.
function EventFactory:register_trigger_type(type_name, builder, definition)
  self.type_catalog:register("trigger", type_name, builder, definition)
end

-- Registers a serializable command type in the current project type catalog.
function EventFactory:register_command_type(type_name, builder, definition)
  self.type_catalog:register("command", type_name, builder, definition)
end

-- Registers a named runtime action callable by serialized event commands.
function EventFactory:register_action(name, callback)
  assert(type(name) == "string", "event action name must be a string")
  assert(type(callback) == "function", "event action callback must be a function")
  self.actions[name] = callback
end

-- Returns a named runtime action registered for serialized event commands.
function EventFactory:get_action(name)
  return self.actions[name]
end

-- Returns whether a named runtime event action is registered.
function EventFactory:has_action(name)
  return self.actions[name] ~= nil
end

-- Builds one runtime event trigger from its serializable definition.
function EventFactory:_build_trigger(definition)
  assert(type(definition) == "table", "trigger definition must be a table")
  assert(type(definition.type) == "string", "trigger definition requires a type")

  return self.type_catalog:create("trigger", definition, {
    event_factory = self
  })
end

-- Builds one runtime event command from its serializable definition.
function EventFactory:_build_command(definition)
  assert(type(definition) == "table", "command definition must be a table")
  assert(type(definition.type) == "string", "command definition requires a type")

  return self.type_catalog:create("command", definition, {
    event_factory = self
  })
end

-- Builds one runtime event page from its serializable definition.
function EventFactory:_build_page(definition)
  assert(type(definition) == "table", "event page definition must be a table")

  local commands = {}

  for _, command_definition in ipairs(definition.commands or {}) do
    table.insert(commands, self:_build_command(command_definition))
  end

  return EventPage.new({
    trigger = self:_build_trigger(definition.trigger),
    commands = commands
  })
end

-- Creates a runtime event from a serializable definition.
function EventFactory:create(definition)
  assert(type(definition) == "table", "event definition must be a table")
  assert(type(definition.id) == "string", "event definition requires an id")

  local pages = {}

  for _, page_definition in ipairs(definition.pages or {}) do
    table.insert(pages, self:_build_page(page_definition))
  end

  return Event.new({
    id = definition.id,
    execution_mode = definition.execution_mode,
    pages = pages
  })
end

return EventFactory
