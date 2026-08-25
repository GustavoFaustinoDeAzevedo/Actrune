local ResourceRegistry = {}
ResourceRegistry.__index = ResourceRegistry

-- Creates an empty named resource registry.
function ResourceRegistry.new()
  return setmetatable({ resources = {} }, ResourceRegistry)
end

-- Registers a resource under a unique name.
function ResourceRegistry:register(name, resource)
  assert(type(name) == "string", "resource name must be a string")
  assert(resource ~= nil, "resource is required")
  assert(self.resources[name] == nil, "resource is already registered: " .. name)

  self.resources[name] = resource
  return resource
end

-- Returns a named resource or nil when it does not exist.
function ResourceRegistry:get(name)
  if name == nil then return nil end
  return self.resources[name]
end

-- Returns whether a named resource exists.
function ResourceRegistry:has(name)
  return self.resources[name] ~= nil
end

-- Removes a named resource.
function ResourceRegistry:remove(name)
  local resource = self.resources[name]
  self.resources[name] = nil
  return resource
end

return ResourceRegistry
