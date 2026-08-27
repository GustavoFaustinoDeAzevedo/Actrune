local TypeCatalog = {}
TypeCatalog.__index = TypeCatalog

-- Creates an empty catalog containing named factory registries.
function TypeCatalog.new()
  return setmetatable({
    registries = {}
  }, TypeCatalog)
end

-- Registers an independent factory registry under a capability name.
function TypeCatalog:register_registry(kind, registry)
  assert(type(kind) == "string", "type catalog kind must be a string")
  assert(registry ~= nil, "type catalog registry is required")
  assert(self.registries[kind] == nil, "type catalog registry is already registered: " .. kind)

  self.registries[kind] = registry
end

-- Returns a registered factory registry.
function TypeCatalog:get_registry(kind)
  return self.registries[kind]
end

-- Returns whether a named factory registry exists.
function TypeCatalog:has_registry(kind)
  return self.registries[kind] ~= nil
end

-- Registers one type in a named catalog registry.
function TypeCatalog:register(kind, type_name, factory, definition)
  local registry = self.registries[kind]
  assert(registry ~= nil, "unknown type catalog registry: " .. tostring(kind))
  registry:register(type_name, factory, definition)
end

-- Creates one runtime object using a named type family and serializable definition.
function TypeCatalog:create(kind, definition, context)
  assert(type(definition) == "table", tostring(kind) .. " definition must be a table")
  assert(type(definition.type) == "string", tostring(kind) .. " definition requires a type")

  local registry = self.registries[kind]
  assert(registry ~= nil, "unknown type catalog registry: " .. tostring(kind))

  local resolve_context = {}
  for name, value in pairs(context or {}) do resolve_context[name] = value end
  resolve_context.catalog = self

  return registry:create(definition.type, definition, resolve_context)
end

return TypeCatalog
