local TypeRegister = {}
TypeRegister.__index = TypeRegister

-- Creates a catalog registration facade associated with one provider.
function TypeRegister.new(catalog, options)
  options = options or {}

  local self = setmetatable({}, TypeRegister)

  self.catalog = catalog
  self.provider = options.provider

  assert(self.catalog ~= nil, "type register requires a type catalog")
  assert(type(self.provider) == "string", "type register provider must be a string")
  assert(self.provider ~= "", "type register provider must not be empty")

  return self
end

-- Returns whether a named type family already exists.
function TypeRegister:has_registry(kind)
  return self.catalog:has_registry(kind)
end

-- Returns an existing type family or creates it when necessary.
function TypeRegister:ensure_registry(kind, options)
  return self.catalog:ensure_registry(kind, options)
end

-- Registers one type and associates it with this register's provider.
function TypeRegister:register(kind, type_name, factory, definition)
  self.catalog:register(kind, type_name, factory, definition, {
    provider = self.provider
  })
end

return TypeRegister
