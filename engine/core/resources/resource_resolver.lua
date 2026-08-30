local ResourceRegistry = require("engine.core.resources.resource_registry")

local ResourceResolver = {}
ResourceResolver.__index = ResourceResolver

-- Creates a lazy resolver for one complete collection of project resource definitions.
function ResourceResolver.new(configuration, definitions)
  assert(configuration ~= nil, "resource resolver requires a project configuration")
  assert(type(definitions) == "table", "resource resolver definitions must be a table")

  return setmetatable({
    configuration = configuration,
    definitions = definitions,
    registries = {},
    resolving = {},
    resolution_stack = {}
  }, ResourceResolver)
end

-- Returns a stable identifier for one named resource.
local function resource_key(type_name, name)
  return type_name .. "\0" .. name
end

-- Returns a readable identifier for diagnostics.
local function resource_label(type_name, name)
  return type_name .. ":" .. name
end

-- Returns or creates the runtime registry associated with one resource type.
function ResourceResolver:_get_registry(type_name)
  local registry = self.registries[type_name]

  if registry == nil then
    registry = ResourceRegistry.new()
    self.registries[type_name] = registry
  end

  return registry
end

-- Returns whether one serializable resource definition exists.
function ResourceResolver:has_definition(type_name, name)
  local type_definitions = self.definitions[type_name]
  return type(type_definitions) == "table" and type_definitions[name] ~= nil
end

-- Builds a readable circular dependency diagnostic from the current resolution stack.
function ResourceResolver:_build_cycle_message(start_index, repeated_label)
  local dependencies = {}

  for index = start_index, #self.resolution_stack do
    table.insert(dependencies, self.resolution_stack[index])
  end

  table.insert(dependencies, repeated_label)

  return "cyclic resource dependency detected: " .. table.concat(dependencies, " -> ")
end

-- Resolves one named runtime resource, recursively resolving its dependencies when necessary.
function ResourceResolver:resolve(type_name, name)
  assert(type(type_name) == "string" and type_name ~= "", "resource type name must be a non-empty string")
  assert(type(name) == "string" and name ~= "", "resource name must be a non-empty string")
  assert(self.configuration:has_resource_type(type_name), "unknown resource type: " .. type_name)

  local registry = self:_get_registry(type_name)
  if registry:has(name) then return registry:get(name) end

  local type_definitions = self.definitions[type_name]
  local definition = type_definitions and type_definitions[name]

  assert(definition ~= nil, "unknown resource: " .. resource_label(type_name, name))

  local key = resource_key(type_name, name)
  local label = resource_label(type_name, name)
  local resolving_index = self.resolving[key]

  if resolving_index ~= nil then error(self:_build_cycle_message(resolving_index, label), 0) end

  table.insert(self.resolution_stack, label)
  self.resolving[key] = #self.resolution_stack

  local success, result = pcall(function()
    return self.configuration:create_resource(type_name, definition, {
      resource_type = type_name,
      resource_name = name,
      resolve_resource = function(dependency_type, dependency_name)
        return self:resolve(dependency_type, dependency_name)
      end
    })
  end)

  self.resolving[key] = nil
  table.remove(self.resolution_stack)

  if not success then error(result, 0) end

  assert(result ~= nil, "resource factory returned nil: " .. label)

  registry:register(name, result)
  return result
end

-- Resolves every project resource in deterministic type and name order.
function ResourceResolver:resolve_all()
  local type_names = {}

  for type_name in pairs(self.definitions) do table.insert(type_names, type_name) end
  table.sort(type_names)

  for _, type_name in ipairs(type_names) do
    assert(self.configuration:has_resource_type(type_name), "unknown resource type: " .. type_name)

    local names = {}
    for name in pairs(self.definitions[type_name]) do table.insert(names, name) end
    table.sort(names)

    for _, name in ipairs(names) do self:resolve(type_name, name) end
  end

  return self.registries
end

return ResourceResolver
