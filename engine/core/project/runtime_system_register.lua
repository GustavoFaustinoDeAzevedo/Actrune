local RuntimeSystemRegister = {}
RuntimeSystemRegister.__index = RuntimeSystemRegister

-- Creates a runtime system register associated with one provider.
function RuntimeSystemRegister.new(registry, options)
  options = options or {}

  local self = setmetatable({}, RuntimeSystemRegister)

  self.registry = registry
  self.provider = options.provider

  assert(self.registry ~= nil, "runtime system register requires a registry")
  assert(type(self.provider) == "string", "runtime system register provider must be a string")
  assert(self.provider ~= "", "runtime system register provider must not be empty")

  return self
end

-- Registers one runtime system under this register's provider.
function RuntimeSystemRegister:register(name, factory, order)
  self.registry:register(name, factory, order, {
    provider = self.provider
  })
end

-- Returns the provider associated with this runtime system register.
function RuntimeSystemRegister:get_provider()
  return self.provider
end

return RuntimeSystemRegister
