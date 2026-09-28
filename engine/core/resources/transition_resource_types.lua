local FadeTransition = require("engine.render.transitions.fade_transition")
local MapCameraCut = require("engine.render.transitions.map_camera_cut")

local TransitionResourceTypes = {}

--- Registers optional built-ins through the existing extensible type catalog.
---@param register table Provider-scoped project register.
---@param catalog table Project type catalog used to instantiate selected types.
function TransitionResourceTypes.register(register, catalog)
  register:ensure_type_registry("transition_effect")
  register:ensure_type_registry("camera_transition")
  register:register_type("transition_effect", "fade", FadeTransition.new, {
    fields = {
      { name = "cover_duration",  type = "number", default = 0.12, min = 0 },
      { name = "reveal_duration", type = "number", default = 0.18, min = 0 }
    }
  })

  register:register_type("camera_transition", "cut", function(definition, context)
    return MapCameraCut.new({
      control = context.control,
      bounds = context.bounds,
      target = context.target,
      retain_map = context.retain_map,
      acquire = context.acquire,
      create_effect = function()
        return catalog:create("transition_effect", definition.effect, context)
      end
    })
  end, {
    fields = {
      { name = "effect", type = "transition_effect", required = true }
    }
  })

  register:register_resource_type("camera_transition", function(definition, resource_context)
    assert(definition.pause_simulation == nil or type(definition.pause_simulation) == "boolean",
      "pause_simulation must be a boolean")
    return {
      --- Composes a controller with runtime capabilities supplied only at scene creation.
      ---@param self table Shared read-only preset.
      ---@param options table Camera and narrow runtime capabilities.
      ---@return table controller Independent controller exposing update, draw and cancel.
      create = function(self, options)
        local context = { resolve_resource = resource_context.resolve_resource }
        for name, value in pairs(options) do context[name] = value end
        context.acquire = nil
        if definition.pause_simulation ~= false then
          assert(type(context.suspend) == "function", "paused transitions require suspension")
          context.acquire = context.suspend
        end
        context.suspend = nil
        return catalog:create("camera_transition", definition.controller, context)
      end
    }
  end, {
    fields = {
      { name = "controller",       type = "camera_transition", required = true },
      { name = "pause_simulation", type = "boolean",           default = true }
    }
  })
end

return TransitionResourceTypes
