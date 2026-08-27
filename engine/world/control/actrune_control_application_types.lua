local ActruneControlApplicationTypes = {}

-- Copies an application context while replacing its active state.
local function with_active(context, active)
  local result = {}
  for name, value in pairs(context or {}) do result[name] = value end
  result.active = active
  return result
end

-- Registers the built-in Actrune control application family in a type catalog.
function ActruneControlApplicationTypes.register(catalog)
  assert(catalog ~= nil, "Actrune control application types require a type catalog")

  catalog:ensure_registry("control_application", { kind = "control application" })

  catalog:register("control_application", "while_active", function()
    local policy = {}

    -- Returns whether the controlled operation should be applied during this update.
    function policy:should_apply(context)
      return context.active == true
    end

    return policy
  end, {
    fields = {}
  })

  catalog:register("control_application", "on_activation", function()
    local policy = { was_active = false }

    -- Returns whether this update represents a new control activation.
    function policy:should_apply(context)
      local active = context.active == true

      if not active then
        self.was_active = false; return false
      end
      if self.was_active then return false end

      self.was_active = true
      return true
    end

    return policy
  end, {
    fields = {}
  })

  catalog:register("control_application", "on_change", function(definition)
    local fields = definition.fields or {}

    assert(type(fields) == "table", "on_change fields must be a table")
    assert(#fields > 0, "on_change requires at least one field")

    for _, field in ipairs(fields) do assert(type(field) == "string", "on_change field names must be strings") end

    local policy = { previous_values = nil }

    -- Returns whether the configured active context values changed since the previous update.
    function policy:should_apply(context)
      if context.active ~= true then
        self.previous_values = nil; return false
      end

      local current_values = {}

      for index, field in ipairs(fields) do
        local value = context[field]
        assert(value ~= nil, "on_change context does not contain field: " .. field)
        current_values[index] = value
      end

      if self.previous_values == nil then
        self.previous_values = current_values; return true
      end

      local changed = false

      for index, value in ipairs(current_values) do
        if value ~= self.previous_values[index] then
          changed = true; break
        end
      end

      self.previous_values = current_values
      return changed
    end

    return policy
  end, {
    fields = {
      { name = "fields", type = "string_list", required = true, min_items = 1 }
    }
  })

  catalog:register("control_application", "when", function(definition, context)
    local condition = context.catalog:create("condition_expression", definition.condition, context)
    local application = context.catalog:create("control_application", definition.application, context)
    local policy = {}

    -- Applies the wrapped policy only while its condition is satisfied.
    function policy:should_apply(resolve_context)
      local enabled = condition:resolve(resolve_context)
      return application:should_apply(with_active(resolve_context, enabled and resolve_context.active == true))
    end

    return policy
  end, {
    fields = {
      { name = "condition",   type = "condition_expression", required = true },
      { name = "application", type = "control_application",  required = true }
    }
  })
end

return ActruneControlApplicationTypes
