local DefinitionValidator = require("engine.core.definitions.definition_validator")
local EventPage = require("engine.events.event_page")

local EventDefinitionValidator = {}

-- Adds one structured event validation error.
local function add_error(errors, path, message)
  table.insert(errors, {
    path = path,
    message = message
  })
end

-- Appends validation errors produced by another validator.
local function append_errors(errors, source)
  for _, validation_error in ipairs(source or {}) do table.insert(errors, validation_error) end
end

-- Validates one serialized event trigger through the active project type catalog.
local function validate_trigger(errors, definition, path, context)
  append_errors(errors, DefinitionValidator.validate_catalog(definition, "trigger", path, context))
end

-- Validates one serialized event command through the active project type catalog.
local function validate_command(errors, definition, path, context)
  append_errors(errors, DefinitionValidator.validate_catalog(definition, "command", path, context))
end

-- Validates one serialized event page and its trigger and commands.
local function validate_page(errors, definition, path, context)
  if type(definition) ~= "table" then
    add_error(errors, path, "must be a table")
    return
  end
  local map_error = EventPage.validate_required_maps(definition.required_maps)
  if map_error ~= nil then add_error(errors, path .. ".required_maps", map_error) end
  if definition.trigger == nil then
    add_error(errors, path .. ".trigger", "is required")
  else
    validate_trigger(errors, definition.trigger, path .. ".trigger", context)
  end

  if definition.commands ~= nil and type(definition.commands) ~= "table" then
    add_error(errors, path .. ".commands", "must be a table")
    return
  end

  for command_index, command_definition in ipairs(definition.commands or {}) do
    validate_command(errors, command_definition, path .. ".commands[" .. command_index .. "]", context)
  end
end

-- Validates one serialized event and all of its pages.
local function validate_event(errors, definition, path, context)
  if type(definition) ~= "table" then
    add_error(errors, path, "must be a table")
    return
  end

  if type(definition.id) ~= "string" then add_error(errors, path .. ".id", "is required") end

  if definition.execution_mode ~= nil
      and definition.execution_mode ~= "parallel"
      and definition.execution_mode ~= "single"
  then
    add_error(errors, path .. ".execution_mode", "invalid value '" .. tostring(definition.execution_mode) .. "'")
  end

  if definition.pages ~= nil and type(definition.pages) ~= "table" then
    add_error(errors, path .. ".pages", "must be a table")
    return
  end

  for page_index, page_definition in ipairs(definition.pages or {}) do
    validate_page(errors, page_definition, path .. ".pages[" .. page_index .. "]", context)
  end
end

-- Validates all serialized events attached to one entity.
function EventDefinitionValidator.validate(definitions, path, context)
  local errors = {}

  if definitions == nil then return errors end

  if type(definitions) ~= "table" then
    add_error(errors, path, "must be a table")
    return errors
  end

  local ids = {}

  for event_index, event_definition in ipairs(definitions) do
    local event_path = path .. "[" .. event_index .. "]"

    validate_event(errors, event_definition, event_path, context)

    if type(event_definition) == "table" and type(event_definition.id) == "string" then
      if ids[event_definition.id] then
        add_error(errors, event_path .. ".id", "duplicates event id '" .. event_definition.id .. "'")
      else
        ids[event_definition.id] = true
      end
    end
  end

  return errors
end

return EventDefinitionValidator
