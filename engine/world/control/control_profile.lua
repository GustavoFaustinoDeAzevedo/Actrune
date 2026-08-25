local ControlProfile = {}
ControlProfile.__index = ControlProfile

-- Creates a control profile containing logical control channels.
function ControlProfile.new(options)
  options = options or {}

  local self = setmetatable({}, ControlProfile)
  self.axes = options.axes or {}
  self.vectors = options.vectors or {}
  self.actions = options.actions or {}

  return self
end

-- Resolves a named control axis against the current runtime input state.
function ControlProfile:resolve_axis(name, runtime)
  local axis = self.axes[name]
  assert(axis ~= nil, "unknown control axis: " .. tostring(name))
  return axis:resolve(runtime)
end

-- Resolves a named two-dimensional control vector.
function ControlProfile:resolve_vector(name, runtime)
  local vector = self.vectors[name]
  assert(vector ~= nil, "unknown control vector: " .. tostring(name))
  return vector:resolve(runtime)
end

-- Returns the runtime action associated with a logical control action.
function ControlProfile:get_action(name)
  local action = self.actions[name]
  assert(action ~= nil, "unknown control action: " .. tostring(name))
  return action
end

return ControlProfile
