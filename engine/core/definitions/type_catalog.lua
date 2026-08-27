local FactoryRegistry = require("engine.core.definitions.factory_registry")

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

-- Returns an existing registry or creates one for the requested type family.
function TypeCatalog:ensure_registry(kind, options)
  assert(type(kind) == "string", "type catalog kind must be a string")

  local registry = self.registries[kind]
  if registry ~= nil then return registry end

  options = options or {}

  registry = FactoryRegistry.new({
    kind = options.kind or kind
  })

  self.registries[kind] = registry

  return registry
end

-- Returns a registered factory registry.
function TypeCatalog:get_registry(kind)
  return self.registries[kind]
end

-- Returns whether a named factory registry exists.
function TypeCatalog:has_registry(kind)
  return self.registries[kind] ~= nil
end

-- Returns whether a named type exists in one catalog family.
function TypeCatalog:has(kind, type_name)
  local registry = self.registries[kind]
  return registry ~= nil and registry:has(type_name)
end

-- Registers one type in a named catalog registry.
function TypeCatalog:register(kind, type_name, factory, definition)
  local registry = self.registries[kind]
  assert(registry ~= nil, "unknown type catalog registry: " .. tostring(kind))

  registry:register(type_name, factory, definition)
end

-- Returns metadata associated with one registered type.
function TypeCatalog:get_definition(kind, type_name)
  local registry = self.registries[kind]
  if registry == nil then return nil end

  return registry:get_definition(type_name)
end

-- Returns all type names registered in one family in deterministic order.
function TypeCatalog:get_type_names(kind)
  local registry = self.registries[kind]
  if registry == nil then return {} end

  return registry:get_type_names()
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
