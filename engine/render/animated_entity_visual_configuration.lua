local AnimatedEntityVisualConfiguration = {}
AnimatedEntityVisualConfiguration.__index = AnimatedEntityVisualConfiguration

-- Creates a reusable configuration for one animated entity visual system.
function AnimatedEntityVisualConfiguration.new(bindings)
  assert(bindings ~= nil and type(bindings.get_count) == "function" and type(bindings.get) == "function",
    "animated entity visual configuration requires an indexed binding collection")

  return setmetatable({
    bindings = bindings
  }, AnimatedEntityVisualConfiguration)
end

-- Returns the binding collection used to instantiate runtime entity visuals.
function AnimatedEntityVisualConfiguration:get_bindings()
  return self.bindings
end

return AnimatedEntityVisualConfiguration