local InputMap = {}
InputMap.__index = InputMap

-- Creates an input map containing hardware and spatial action bindings.
function InputMap.new(options)
  options = options or {}

  local self = setmetatable({}, InputMap)
  self.keys = options.keys or {}
  self.spatial_actions = options.spatial_actions or {}

  return self
end

-- Binds all configured hardware and spatial actions to an Actrune runtime.
function InputMap:bind(runtime)
  assert(runtime ~= nil, "runtime is required")

  for _, binding in ipairs(self.keys) do
    runtime:bind_key(binding.action, binding.key)
  end

  for _, binding in ipairs(self.spatial_actions) do
    runtime:bind_spatial_action(binding.action, {
      activator_shape = binding.activator_shape,
      target_shape = binding.target_shape,
      trigger = binding.trigger
    })
  end
end

return InputMap
