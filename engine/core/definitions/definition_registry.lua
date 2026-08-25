local DefinitionRegistry = {}
DefinitionRegistry.__index = DefinitionRegistry

-- Creates an empty registry of data type definitions.
function DefinitionRegistry.new()
  return setmetatable({
    categories = {},
    order = {}
  }, DefinitionRegistry)
end

-- Returns or creates the storage for one definition category.
function DefinitionRegistry:_get_category(category)
  local storage = self.categories[category]

  if storage == nil then
    storage = {
      definitions = {},
      order = {}
    }

    self.categories[category] = storage
    table.insert(self.order, category)
  end

  return storage
end

-- Registers metadata describing one named data type.
function DefinitionRegistry:register(category, type_name, definition)
  assert(type(category) == "string", "definition category must be a string")
  assert(type(type_name) == "string", "definition type name must be a string")
  assert(type(definition) == "table", "definition metadata must be a table")

  local storage = self:_get_category(category)

  assert(storage.definitions[type_name] == nil, "definition is already registered: " .. category .. "." .. type_name)

  storage.definitions[type_name] = definition
  table.insert(storage.order, type_name)

  return definition
end

-- Returns whether a named definition exists.
function DefinitionRegistry:has(category, type_name)
  local storage = self.categories[category]
  return storage ~= nil and storage.definitions[type_name] ~= nil
end

-- Returns one named definition or nil when it does not exist.
function DefinitionRegistry:get(category, type_name)
  local storage = self.categories[category]
  if storage == nil then return nil end
  return storage.definitions[type_name]
end

-- Returns all definitions in deterministic registration order.
function DefinitionRegistry:list(category)
  local storage = self.categories[category]
  if storage == nil then return {} end

  local result = {}

  for _, type_name in ipairs(storage.order) do
    table.insert(result, {
      type = type_name,
      definition = storage.definitions[type_name]
    })
  end

  return result
end

-- Returns all registered definition categories in registration order.
function DefinitionRegistry:list_categories()
  local result = {}

  for _, category in ipairs(self.order) do table.insert(result, category) end

  return result
end

return DefinitionRegistry
