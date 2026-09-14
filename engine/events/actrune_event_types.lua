local DirectionalAreaTrigger = require("engine.events.triggers.directional_area_trigger")
local CallCommand = require("engine.events.commands.call_command")
local WaitCommand = require("engine.events.commands.wait_command")
local EventTrigger = require("engine.events.event_trigger")

local ActruneEventTypes = {}

-- Registers the built-in Actrune trigger and command families in a type catalog.
function ActruneEventTypes.register(catalog)
  assert(catalog ~= nil, "Actrune event types require a type catalog")

  catalog:ensure_registry("trigger", { kind = "trigger" })
  catalog:ensure_registry("command", { kind = "command" })

  -- Named signals reuse the existing trigger without requiring spatial shapes.
  catalog:register("trigger", "signal", function(definition)
    assert(type(definition.action) == "string" and definition.action ~= "",
      "signal trigger requires a non-empty action")
    return EventTrigger.new(definition.action)
  end, {
    fields = {
      { name = "action", type = "string", required = true }
    }
  })

  catalog:register("trigger", "directional_area", function(definition)
    return DirectionalAreaTrigger.new({
      type = definition.action,
      shape = definition.shape,
      activator_shape = definition.activator_shape,
      max_angle = definition.max_angle,
      vertical_mode = definition.vertical_mode,
      target_vertical_range = definition.target_vertical_range,
      activator_vertical_range = definition.activator_vertical_range,
      enabled = definition.enabled,
    })
  end, {
    fields = {
      { name = "action",                   type = "string",          required = true },
      { name = "shape",                    type = "shape_reference", required = true },
      { name = "activator_shape",          type = "string",          required = true },
      { name = "max_angle",                type = "number",          optional = true },
      { name = "vertical_mode",            type = "enum",            values = { "overlap", "ignore" }, required = true },
      { name = "target_vertical_range",    type = "string",          optional = true },
      { name = "activator_vertical_range", type = "string",          optional = true },
      { name = "enabled",                  type = "boolean",         default = true },
    }
  })

  catalog:register("command", "wait", function(definition)
    return WaitCommand.new(definition.duration)
  end, {
    fields = {
      { name = "duration", type = "number", required = true, min = 0 }
    }
  })

  catalog:register("command", "call", function(definition, context)
    assert(context.action_bindings ~= nil, "call command requires event action bindings")

    local action = context.action_bindings:get(definition.action)
    assert(action ~= nil, "unknown event action: " .. tostring(definition.action))

    return CallCommand.new(action)
  end, {
    fields = {
      { name = "action", type = "action_reference", required = true }
    }
  })
end

return ActruneEventTypes
