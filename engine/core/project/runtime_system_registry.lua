local RuntimeSystemRegistry = {}
RuntimeSystemRegistry.__index = RuntimeSystemRegistry

-- Creates an ordered registry of project runtime system factories.
function RuntimeSystemRegistry.new()
  return setmetatable({
    definitions = {}
  }, RuntimeSystemRegistry)
end

-- Registers a named runtime system factory with an execution order.
function RuntimeSystemRegistry:register(name, factory, order)
  assert(type(name) == "string", "runtime system name must be a string")
  assert(type(factory) == "function", "runtime system factory must be a function")
  assert(type(order or 0) == "number", "runtime system order must be a number")

  for _, definition in ipairs(self.definitions) do
    assert(definition.name ~= name, "runtime system is already registered: " .. name)
  end

  table.insert(self.definitions, {
    name = name,
    factory = factory,
    order = order or 0
  })
end

-- Returns runtime system definitions sorted deterministically by order and name.
function RuntimeSystemRegistry:get_definitions()
  local definitions = {}

  for _, definition in ipairs(self.definitions) do definitions[#definitions + 1] = definition end

  table.sort(definitions, function(a, b)
    if a.order ~= b.order then return a.order < b.order end
    return a.name < b.name
  end)

  return definitions
end

return RuntimeSystemRegistry
