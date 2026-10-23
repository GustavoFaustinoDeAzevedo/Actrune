local FadeTransition = require("engine.render.transitions.fade_transition")
local MapCameraCut = require("engine.render.transitions.map_camera_cut")
local MapCameraTransition = require("engine.render.transitions.map_camera_transition")
local CameraSlideTransition = require("engine.render.transitions.camera_slide_transition")
local RoutedMapCameraTransition = require("engine.render.transitions.routed_map_camera_transition")

local TransitionResourceTypes = {}

--- Registers optional built-ins through the existing extensible type catalog.
---@param register table Provider-scoped project register.
---@param catalog table Project type catalog used to instantiate selected types.
function TransitionResourceTypes.register(register, catalog)
  register:ensure_type_registry("transition_effect")
  register:ensure_type_registry("camera_transition")
  register:ensure_type_registry("transition_curve")

  register:register_type("transition_curve", "linear", function()
    return function(progress) return progress end
  end, { fields = {} })
  register:register_type("transition_curve", "smoothstep", function()
    return function(progress) return progress * progress * (3 - 2 * progress) end
  end, { fields = {} })
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

  register:register_type("camera_transition", "slide", function(definition, context)
    local duration = definition.duration
    if duration == nil then duration = 0.45 end
    assert(type(duration) == "number" and duration >= 0 and duration < math.huge,
      "camera slide duration must be finite and non-negative")
    local curve = catalog:create("transition_curve",
      definition.curve or { type = "smoothstep" }, context)
    return MapCameraTransition.new({
      control = context.control,
      bounds = context.bounds,
      target = context.target,
      retain_map = context.retain_map,
      acquire = context.acquire,
      create_effect = function()
        return CameraSlideTransition.new(context.control.camera,
          function() return context.control:resolve_target() end, duration, curve)
      end,
      apply_position = function(control, effect)
        if effect == nil then
          control:snap(); return
        end
        ---@cast effect CameraSlideTransition
        effect:apply()
      end
    })
  end, {
    fields = {
      { name = "duration", type = "number",           default = 0.45, min = 0 },
      { name = "curve",    type = "transition_curve", optional = true }
    }
  })

  register:register_resource_type("map_camera_transition_routes", function(definition, context)
    local layout = context.resolve_resource("map_layout", definition.layout)
    local fallback = context.resolve_resource("camera_transition", definition.default)
    local connections = definition.connections or {}
    local resolved = {}
    assert(type(connections) == "table", "camera connections must be a table")

    for source, destinations in pairs(connections) do
      assert(type(source) == "string" and layout:get_map(source) ~= nil,
        "camera connection references unknown source: " .. tostring(source))
      assert(type(destinations) == "table", "camera destinations must be a table: " .. source)
      local row = {}
      resolved[source] = row
      for destination, name in pairs(destinations) do
        assert(type(destination) == "string" and layout:get_map(destination) ~= nil,
          "camera connection references unknown destination: " .. tostring(destination))
        assert(source ~= destination, "camera connection requires different maps: " .. source)
        assert(type(name) == "string" and name ~= "",
          "camera connection requires a preset: " .. source .. " -> " .. destination)
        row[destination] = context.resolve_resource("camera_transition", name)
      end
    end

    --- Selects exact directed connections; absent endpoints use the default preset.
    ---@param previous? MapRegion Last presented map.
    ---@param current? MapRegion Sampled destination.
    ---@return CameraTransitionPreset preset Shared resolved preset.
    local function select_preset(previous, current)
      local row = previous and resolved[previous.id]
      return row and current and row[current.id] or fallback
    end

    return {
      --- Creates independent routing state for one camera using the configured layout.
      ---@param self table Shared resolved route configuration.
      ---@param options CameraTransitionContext Camera and narrow runtime capabilities.
      ---@return RoutedMapCameraTransition controller New routing controller.
      create = function(self, options)
        assert(options.bounds.configuration.layout == layout,
          "camera routes and bounds must use the same layout")
        return RoutedMapCameraTransition.new(options, select_preset)
      end
    }
  end, {
    fields = {
      { name = "layout",      type = "resource_reference", resource_type = "map_layout",        required = true },
      { name = "default",     type = "resource_reference", resource_type = "camera_transition", required = true },
      { name = "connections", type = "property_map",       optional = true }
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
