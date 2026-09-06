local EntityVisualConfiguration = {}
EntityVisualConfiguration.__index = EntityVisualConfiguration

-- Creates a runtime visual configuration backed by one entity visual binding collection.
function EntityVisualConfiguration.new(bindings)
  assert(bindings ~= nil and type(bindings.get_count) == "function",
    "entity visual configuration requires bindings exposing get_count")
  assert(type(bindings.get) == "function",
    "entity visual configuration requires bindings exposing get")

  -- The configuration only selects which declarative bindings belong to one visual system.
  return setmetatable({
    bindings = bindings
  }, EntityVisualConfiguration)
end

-- Returns the binding collection selected by this configuration.
function EntityVisualConfiguration:get_bindings()
  return self.bindings
end

return EntityVisualConfiguration
