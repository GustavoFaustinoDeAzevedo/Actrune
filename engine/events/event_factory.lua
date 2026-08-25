local Event = require("engine.events.event")
local EventPage = require("engine.events.event_page")
local DirectionalAreaTrigger = require("engine.events.triggers.directional_area_trigger")
local CallCommand = require("engine.events.commands.call_command")
local WaitCommand = require("engine.events.commands.wait_command")

local EventFactory = {}
EventFactory.__index = EventFactory

-- Creates an event factory with built-in trigger and command types.
function EventFactory.new(definitions)
  local self = setmetatable({}, EventFactory)

  self.definitions = definitions
  self.trigger_builders = {}
  self.command_builders = {}
  self.actions = {}

  self:register_trigger_type("directional_area", function(definition)
    return DirectionalAreaTrigger.new({
      type = definition.action,
      shape = definition.shape,
      activator_shape = definition.activator_shape,
      max_angle = definition.max_angle
    })
  end, {
    fields = {
      { name = "action",          type = "string",          required = true },
      { name = "shape",           type = "shape_reference", required = true },
      { name = "activator_shape", type = "string",          required = true },
      { name = "max_angle",       type = "number",          optional = true }
    }
  })

  self:register_command_type("wait", function(definition)
    return WaitCommand.new(definition.duration)
  end, {
    fields = {
      { name = "duration", type = "number", required = true, min = 0 }
    }
  })

  self:register_command_type("call", function(definition)
    local action = self.actions[definition.action]
    assert(action ~= nil, "unknown event action: " .. tostring(definition.action))
    return CallCommand.new(action)
  end, {
    fields = {
      { name = "action", type = "action_reference", required = true }
    }
  })

  return self
end

-- Registers a serializable trigger type and its runtime builder.
function EventFactory:register_trigger_type(type_name, builder, definition)
  assert(type(type_name) == "string", "trigger type name must be a string")
  assert(type(builder) == "function", "trigger builder must be a function")

  self.trigger_builders[type_name] = builder

  if definition ~= nil and self.definitions ~= nil and not self.definitions:has("trigger", type_name) then
    self.definitions:register("trigger", type_name, definition)
  end
end

-- Registers a serializable command type and its runtime builder.
function EventFactory:register_command_type(type_name, builder, definition)
  assert(type(type_name) == "string", "command type name must be a string")
  assert(type(builder) == "function", "command builder must be a function")

  self.command_builders[type_name] = builder

  if definition ~= nil and self.definitions ~= nil and not self.definitions:has("command", type_name) then
    self.definitions:register("command", type_name, definition)
  end
end

-- Registers a named runtime action callable by serialized event commands.
function EventFactory:register_action(name, callback)
  assert(type(name) == "string", "event action name must be a string")
  assert(type(callback) == "function", "event action callback must be a function")
  self.actions[name] = callback
end

-- Builds one runtime event trigger from its serializable definition.
function EventFactory:_build_trigger(definition)
  assert(type(definition) == "table", "trigger definition must be a table")
  assert(type(definition.type) == "string", "trigger definition requires a type")

  local builder = self.trigger_builders[definition.type]
  assert(builder ~= nil, "unknown trigger type: " .. definition.type)

  return builder(definition)
end

-- Builds one runtime event command from its serializable definition.
function EventFactory:_build_command(definition)
  assert(type(definition) == "table", "command definition must be a table")
  assert(type(definition.type) == "string", "command definition requires a type")

  local builder = self.command_builders[definition.type]
  assert(builder ~= nil, "unknown command type: " .. definition.type)

  return builder(definition)
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
