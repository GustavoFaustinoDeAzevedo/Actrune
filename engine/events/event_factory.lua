local Event = require("engine.events.event")
local EventPage = require("engine.events.event_page")

local EventFactory = {}
EventFactory.__index = EventFactory

-- Creates an event factory backed by project types and runtime action bindings.
function EventFactory.new(type_catalog, action_bindings)
  local self = setmetatable({}, EventFactory)

  self.type_catalog = type_catalog
  self.action_bindings = action_bindings

  assert(self.type_catalog ~= nil, "event factory requires a type catalog")
  assert(self.action_bindings ~= nil, "event factory requires event action bindings")
  assert(self.type_catalog:has_registry("trigger"), "event factory requires a trigger registry")
  assert(self.type_catalog:has_registry("command"), "event factory requires a command registry")

  return self
end

-- Builds one runtime event trigger from its serializable definition.
function EventFactory:_build_trigger(definition)
  assert(type(definition) == "table", "trigger definition must be a table")
  assert(type(definition.type) == "string", "trigger definition requires a type")

  return self.type_catalog:create("trigger", definition, {
    action_bindings = self.action_bindings
  })
end

-- Builds one runtime event command from its serializable definition.
function EventFactory:_build_command(definition)
  assert(type(definition) == "table", "command definition must be a table")
  assert(type(definition.type) == "string", "command definition requires a type")

  return self.type_catalog:create("command", definition, {
    action_bindings = self.action_bindings
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
