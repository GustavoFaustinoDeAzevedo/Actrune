local DirectionalAreaTrigger = require("engine.events.triggers.directional_area_trigger")
local CallCommand = require("engine.events.commands.call_command")
local WaitCommand = require("engine.events.commands.wait_command")

local ActruneEventTypes = {}

-- Registers the built-in Actrune trigger and command families in a type catalog.
function ActruneEventTypes.register(catalog)
  assert(catalog ~= nil, "Actrune event types require a type catalog")

  catalog:ensure_registry("trigger", { kind = "trigger" })
  catalog:ensure_registry("command", { kind = "command" })

  catalog:register("trigger", "directional_area", function(definition)
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

  catalog:register("command", "wait", function(definition)
    return WaitCommand.new(definition.duration)
  end, {
    fields = {
      { name = "duration", type = "number", required = true, min = 0 }
    }
  })

  catalog:register("command", "call", function(definition, context)
    assert(context.event_factory ~= nil, "call command requires an event factory")

    local action = context.event_factory:get_action(definition.action)
    assert(action ~= nil, "unknown event action: " .. tostring(definition.action))

    return CallCommand.new(action)
  end, {
    fields = {
      { name = "action", type = "action_reference", required = true }
    }
  })
end

return ActruneEventTypes
