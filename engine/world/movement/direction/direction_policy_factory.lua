local DirectionPolicyFactory = {}

local builders = {}

-- Creates a direction policy that preserves the supplied direction unchanged.
local function create_identity()
  return {
    -- Returns the supplied direction without modification.
    resolve = function(self, x, y)
      return x, y
    end
  }
end

-- Creates a direction policy that restricts movement to one dominant axis.
local function create_axis_lock(definition)
  local tie_break = definition.tie_break or "x"
  assert(tie_break == "x" or tie_break == "y", "axis_lock tie_break must be 'x' or 'y'")

  return {
    -- Returns only the dominant direction axis, using the configured axis to resolve ties.
    resolve = function(self, x, y)
      local absolute_x = math.abs(x)
      local absolute_y = math.abs(y)

      if absolute_x > absolute_y then return x, 0 end
      if absolute_y > absolute_x then return 0, y end
      if absolute_x == 0 then return 0, 0 end
      if tie_break == "x" then return x, 0 end
      return 0, y
    end
  }
end

-- Creates a direction policy where the most recently changed active axis wins.
local function create_last_changed_axis(definition)
  local initial_axis = definition.initial_axis or "x"
  assert(initial_axis == "x" or initial_axis == "y", "last_changed_axis initial_axis must be 'x' or 'y'")

  local policy = {
    previous_x = 0,
    previous_y = 0,
    selected_axis = nil
  }

  -- Returns one active axis, preferring whichever axis changed most recently.
  function policy:resolve(x, y)
    local x_active = x ~= 0
    local y_active = y ~= 0
    local x_changed = x ~= self.previous_x
    local y_changed = y ~= self.previous_y

    if not x_active and not y_active then
      self.selected_axis = nil
    elseif x_active and not y_active then
      self.selected_axis = "x"
    elseif y_active and not x_active then
      self.selected_axis = "y"
    elseif x_changed and not y_changed then
      self.selected_axis = "x"
    elseif y_changed and not x_changed then
      self.selected_axis = "y"
    elseif self.selected_axis == nil then
      self.selected_axis = initial_axis
    end

    self.previous_x = x
    self.previous_y = y

    if self.selected_axis == "x" then return x, 0 end
    if self.selected_axis == "y" then return 0, y end
    return 0, 0
  end

  return policy
end

-- Registers a constructor for a named direction policy type.
function DirectionPolicyFactory.register_type(type_name, builder)
  assert(type(type_name) == "string", "direction policy type name must be a string")
  assert(type(builder) == "function", "direction policy builder must be a function")
  builders[type_name] = builder
end

-- Creates a direction policy from a serializable definition.
function DirectionPolicyFactory.create(definition)
  definition = definition or { type = "identity" }

  assert(type(definition) == "table", "direction policy definition must be a table")
  assert(type(definition.type) == "string", "direction policy requires a type")

  local builder = builders[definition.type]
  assert(builder ~= nil, "unknown direction policy type: " .. tostring(definition.type))
  return builder(definition)
end

DirectionPolicyFactory.register_type("identity", create_identity)
DirectionPolicyFactory.register_type("axis_lock", create_axis_lock)
DirectionPolicyFactory.register_type("last_changed_axis", create_last_changed_axis)

return DirectionPolicyFactory
