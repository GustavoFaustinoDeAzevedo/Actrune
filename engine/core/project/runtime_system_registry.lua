local RuntimeSystemRegister = require("engine.core.project.runtime_system_register")

local RuntimeSystemRegistry = {}
RuntimeSystemRegistry.__index = RuntimeSystemRegistry

-- Creates an ordered registry of project runtime system factories.
function RuntimeSystemRegistry.new()
  return setmetatable({
    definitions = {},
    definitions_by_name = {}
  }, RuntimeSystemRegistry)
end

-- Registers a named runtime system factory with execution and provider metadata.
function RuntimeSystemRegistry:register(name, factory, order, options)
  assert(type(name) == "string", "runtime system name must be a string")
  assert(type(factory) == "function", "runtime system factory must be a function")
  assert(type(order or 0) == "number", "runtime system order must be a number")
  assert(self.definitions_by_name[name] == nil, "runtime system is already registered: " .. name)

  options = options or {}

  local definition = {
    name = name,
    factory = factory,
    order = order or 0,
    provider = options.provider
  }

  table.insert(self.definitions, definition)
  self.definitions_by_name[name] = definition
end

-- Creates a provider-scoped register for runtime system registration.
function RuntimeSystemRegistry:create_register(options)
  return RuntimeSystemRegister.new(self, options)
end

-- Returns whether a named runtime system is registered.
function RuntimeSystemRegistry:has(name)
  return self.definitions_by_name[name] ~= nil
end

-- Returns the provider associated with one registered runtime system.
function RuntimeSystemRegistry:get_provider(name)
  local definition = self.definitions_by_name[name]
  if definition == nil then return nil end
  return definition.provider
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
