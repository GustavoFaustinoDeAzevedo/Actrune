local DefinitionValidator = {}

-- Adds one validation error with its full data path.
local function add_error(errors, path, message)
  table.insert(errors, {
    path = path,
    message = message
  })
end

-- Returns whether a value exists in an allowed value list.
local function contains(values, target)
  for _, value in ipairs(values or {}) do
    if value == target then return true end
  end

  return false
end

-- Returns whether a value matches the declared primitive or structural field type.
local function matches_type(value, field_type)
  if field_type == "number" then return type(value) == "number" end
  if field_type == "integer" then return type(value) == "number" and value % 1 == 0 end
  if field_type == "string" then return type(value) == "string" end
  if field_type == "boolean" then return type(value) == "boolean" end
  if field_type == "enum" then return type(value) == "string" end
  if field_type == "resource_reference" then return type(value) == "string" end
  if field_type == "shape_reference" then return type(value) == "string" end
  if field_type == "shape_reference_list" then return type(value) == "table" end
  if field_type == "action_reference" then return type(value) == "string" end
  if field_type == "string_list" then return type(value) == "table" end
  if field_type == "point_list" then return type(value) == "table" end
  if field_type == "property_map" then return type(value) == "table" end

  return true
end

-- Validates numeric constraints declared by one field definition.
local function validate_number(errors, path, value, field)
  if field.min ~= nil and value < field.min then
    add_error(errors, path, "must be greater than or equal to " .. tostring(field.min))
  end

  if field.min_exclusive ~= nil and value <= field.min_exclusive then
    add_error(errors, path, "must be greater than " .. tostring(field.min_exclusive))
  end

  if field.max ~= nil and value > field.max then
    add_error(errors, path, "must be less than or equal to " .. tostring(field.max))
  end

  if field.max_exclusive ~= nil and value >= field.max_exclusive then
    add_error(errors, path, "must be less than " .. tostring(field.max_exclusive))
  end
end

-- Validates a list of point definitions.
local function validate_point_list(errors, path, value, field)
  if field.min_items ~= nil and #value < field.min_items then
    add_error(errors, path, "must contain at least " .. tostring(field.min_items) .. " points")
  end

  for index, point in ipairs(value) do
    local point_path = path .. "[" .. index .. "]"

    if type(point) ~= "table" then
      add_error(errors, point_path, "must be a point")
    else
      if type(point.x) ~= "number" then add_error(errors, point_path .. ".x", "must be a number") end
      if type(point.y) ~= "number" then add_error(errors, point_path .. ".y", "must be a number") end
    end
  end
end

-- Validates references to named entity shapes.
local function validate_shape_references(errors, path, value, context)
  for index, shape_name in ipairs(value) do
    local item_path = path .. "[" .. index .. "]"

    if type(shape_name) ~= "string" then
      add_error(errors, item_path, "must be a shape name")
    elseif context.shapes == nil or context.shapes[shape_name] == nil then
      add_error(errors, item_path, "references unknown shape '" .. shape_name .. "'")
    end
  end
end

-- Validates a list containing only strings and its optional size constraints.
local function validate_string_list(errors, path, values, field)
  if field.min_items ~= nil and #values < field.min_items then
    add_error(errors, path, "must contain at least " .. tostring(field.min_items) .. " item(s)")
  end

  if field.max_items ~= nil and #values > field.max_items then
    add_error(errors, path, "must contain at most " .. tostring(field.max_items) .. " item(s)")
  end

  for index, value in ipairs(values) do
    if type(value) ~= "string" then add_error(errors, path .. "[" .. index .. "]", "must be a string") end
  end
end

-- Validates a nested typed definition using metadata from the active type catalog.
local function validate_catalog_definition(errors, path, value, field_type, context)
  local type_catalog = context.type_catalog
  if type_catalog == nil or not type_catalog:has_registry(field_type) then return false end

  if type(value) ~= "table" then
    add_error(errors, path, "has invalid type")
    return true
  end

  if type(value.type) ~= "string" then
    add_error(errors, path .. ".type", "is required")
    return true
  end

  local registry = type_catalog:get_registry(field_type)

  if not registry:has(value.type) then
    add_error(errors, path .. ".type", "unknown " .. field_type .. " type '" .. tostring(value.type) .. "'")
    return true
  end

  local metadata = registry:get_definition(value.type)

  if metadata ~= nil then
    local nested_errors = DefinitionValidator.validate_typed(value, metadata, path, context)
    for _, validation_error in ipairs(nested_errors) do table.insert(errors, validation_error) end
  end

  return true
end

-- Validates one field according to its registered metadata.
local function validate_field(errors, path, value, field, context)
  if value == nil then
    if field.required and field.default == nil then add_error(errors, path, "is required") end
    return
  end

  if validate_catalog_definition(errors, path, value, field.type, context) then return end

  if not matches_type(value, field.type) then
    add_error(errors, path, "has invalid type")
    return
  end

  if field.type == "number" or field.type == "integer" then
    validate_number(errors, path, value, field)
  elseif field.type == "enum" then
    if not contains(field.values, value) then add_error(errors, path, "invalid value '" .. tostring(value) .. "'") end
  elseif field.type == "string_list" then
    validate_string_list(errors, path, value, field)
  elseif field.type == "point_list" then
    validate_point_list(errors, path, value, field)
  elseif field.type == "shape_reference" then
    if context.shapes == nil or context.shapes[value] == nil then
      add_error(errors, path, "references unknown shape '" .. value .. "'")
    end
  elseif field.type == "shape_reference_list" then
    validate_shape_references(errors, path, value, context)
  elseif field.type == "resource_reference" then
    local registry = context.resources and context.resources[field.resource_type]

    if registry == nil or not registry:has(value) then
      add_error(errors, path,
        "references unknown " .. tostring(field.resource_type) .. " resource '" .. tostring(value) .. "'")
    end
  elseif field.type == "action_reference" then
    if context.action_exists ~= nil and not context.action_exists(value) then
      add_error(errors, path, "references unknown event action '" .. tostring(value) .. "'")
    end
  end
end

-- Validates one typed data definition against registered metadata.
function DefinitionValidator.validate_typed(definition, metadata, path, context)
  local errors = {}

  context = context or {}
  metadata = metadata or {}

  for _, field in ipairs(metadata.fields or {}) do
    validate_field(errors, path .. "." .. field.name, definition[field.name], field, context)
  end

  return errors
end

-- Validates one definition belonging to a registered type catalog family.
function DefinitionValidator.validate_catalog(definition, family, path, context)
  local errors = {}

  context = context or {}

  if context.type_catalog == nil or not context.type_catalog:has_registry(family) then
    add_error(errors, path, "unknown type catalog registry '" .. tostring(family) .. "'")
    return errors
  end

  validate_catalog_definition(errors, path, definition, family, context)

  return errors
end

-- Returns whether a validation result contains no errors.
function DefinitionValidator.is_valid(errors)
  return #errors == 0
end

-- Formats one list of validation errors into a readable multiline message.
function DefinitionValidator.format_errors(errors)
  local lines = {}

  for _, validation_error in ipairs(errors) do
    table.insert(lines, validation_error.path .. ": " .. validation_error.message)
  end

  return table.concat(lines, "\n")
end

return DefinitionValidator
