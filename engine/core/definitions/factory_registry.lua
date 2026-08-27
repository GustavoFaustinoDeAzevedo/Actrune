local FactoryRegistry = {}
FactoryRegistry.__index = FactoryRegistry

-- Creates an empty registry of named factories and their optional definitions.
function FactoryRegistry.new(options)
  options = options or {}

  return setmetatable({
    kind = options.kind or "factory",
    entries = {}
  }, FactoryRegistry)
end

-- Registers a named factory with optional definition and registration metadata.
function FactoryRegistry:register(type_name, factory, definition, options)
  assert(type(type_name) == "string", self.kind .. " type name must be a string")
  assert(type(factory) == "function", self.kind .. " factory must be a function")
  assert(self.entries[type_name] == nil, self.kind .. " type is already registered: " .. type_name)

  options = options or {}

  self.entries[type_name] = {
    factory = factory,
    definition = definition,
    provider = options.provider
  }
end

-- Returns whether a named factory type is registered.
function FactoryRegistry:has(type_name)
  return self.entries[type_name] ~= nil
end

-- Creates an instance using a registered named factory.
function FactoryRegistry:create(type_name, definition, context)
  local entry = self.entries[type_name]

  assert(entry ~= nil, "unknown " .. self.kind .. " type: " .. tostring(type_name))

  return entry.factory(definition, context or {})
end

-- Returns metadata associated with a registered type.
function FactoryRegistry:get_definition(type_name)
  local entry = self.entries[type_name]
  if entry == nil then return nil end
  return entry.definition
end

-- Returns the provider associated with a registered type.
function FactoryRegistry:get_provider(type_name)
  local entry = self.entries[type_name]
  if entry == nil then return nil end
  return entry.provider
end

-- Returns all registered type names in deterministic order.
function FactoryRegistry:get_type_names()
  local names = {}

  for type_name in pairs(self.entries) do names[#names + 1] = type_name end

  table.sort(names)
  return names
end

return FactoryRegistry
