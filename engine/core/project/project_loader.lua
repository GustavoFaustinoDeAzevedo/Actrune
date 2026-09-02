local ResourceResolver = require("engine.core.resources.resource_resolver")
local DefinitionValidator = require("engine.core.definitions.definition_validator")
local EntityFactory = require("engine.world.entity_factory")
local EventFactory = require("engine.events.event_factory")
local EventDefinitionValidator = require("engine.events.event_definition_validator")
local EventActionBindings = require("engine.events.event_action_bindings")

local ProjectLoader = {}
ProjectLoader.__index = ProjectLoader

-- Creates a resource existence query backed only by serialized project definitions.
local function create_resource_exists(resource_definitions)
  resource_definitions = resource_definitions or {}

  return function(type_name, name)
    local definitions = resource_definitions[type_name]
    return type(definitions) == "table" and definitions[name] ~= nil
  end
end

-- Creates an entity existence query backed only by serialized project definitions.
local function create_entity_exists(entity_definitions)
  local ids = {}

  for _, definition in ipairs(entity_definitions or {}) do
    if type(definition.id) == "string" then ids[definition.id] = true end
  end

  return function(name)
    return ids[name] == true
  end
end

-- Creates a project loader backed by one complete project configuration.
function ProjectLoader.new(options)
  options = options or {}

  local self = setmetatable({}, ProjectLoader)

  self.configuration = options.configuration

  assert(self.configuration ~= nil, "project loader requires a project configuration")

  self.type_catalog = self.configuration:get_type_catalog()
  self.event_action_bindings = EventActionBindings.new()
  self.event_factory = EventFactory.new(self.type_catalog, self.event_action_bindings)

  return self
end

-- Binds a named runtime callback to a serialized project event action.
function ProjectLoader:register_event_action(name, callback)
  self.event_action_bindings:bind(name, callback)
end

-- Builds all runtime project resources with dependency-aware lazy resolution.
function ProjectLoader:_load_resources(definitions)
  local resolver = ResourceResolver.new(
    self.configuration,
    definitions or {}
  )

  return resolver:resolve_all()
end

-- Creates an entity factory configured with loaded project resources and type registries.
function ProjectLoader:_create_entity_factory(registries)
  local factory = EntityFactory.new(
    self.event_factory,
    self.type_catalog
  )

  for type_name, registry in pairs(registries) do
    factory:register_resource_type(type_name, registry)
  end

  return factory
end

-- Validates all serialized project resources and their declared references without constructing them.
function ProjectLoader:_validate_resources(resource_definitions, entity_definitions)
  local errors = {}
  local resource_exists = create_resource_exists(resource_definitions)
  local entity_exists = create_entity_exists(entity_definitions)

  for type_name, definitions in pairs(resource_definitions or {}) do
    if not self.configuration:has_resource_type(type_name) then
      table.insert(errors, {
        path = "resources." .. type_name,
        message = "unknown resource type"
      })
    else
      local metadata = self.configuration:get_resource_definition(type_name)

      if metadata ~= nil then
        for name, definition in pairs(definitions) do
          local resource_errors = DefinitionValidator.validate_typed(
            definition,
            metadata,
            "resources." .. type_name .. "." .. name,
            {
              type_catalog = self.type_catalog,
              resource_exists = resource_exists,
              entity_exists = entity_exists
            }
          )

          for _, validation_error in ipairs(resource_errors) do table.insert(errors, validation_error) end
        end
      end
    end
  end

  return errors
end

-- Validates all project entities, shapes, components, events, and nested typed definitions.
function ProjectLoader:_validate_entities(entity_definitions, resource_definitions)
  local errors = {}
  local resource_exists = create_resource_exists(resource_definitions)

  for entity_index, entity_definition in ipairs(entity_definitions or {}) do
    local entity_path = "entities[" .. entity_index .. "]"
    local shapes = entity_definition.shapes or {}

    if type(entity_definition.id) ~= "string" then
      table.insert(errors, {
        path = entity_path .. ".id",
        message = "is required"
      })
    end

    for shape_name, shape_definition in pairs(shapes) do
      local shape_path = entity_path .. ".shapes." .. shape_name

      if type(shape_definition) ~= "table" or type(shape_definition.type) ~= "string" then
        table.insert(errors, {
          path = shape_path .. ".type",
          message = "is required"
        })
      elseif not self.type_catalog:has("shape", shape_definition.type) then
        table.insert(errors, {
          path = shape_path .. ".type",
          message = "unknown shape type '" .. tostring(shape_definition.type) .. "'"
        })
      else
        local metadata = self.type_catalog:get_definition("shape", shape_definition.type)

        if metadata ~= nil then
          local shape_errors = DefinitionValidator.validate_typed(
            shape_definition,
            metadata,
            shape_path,
            {
              resource_exists = resource_exists,
              shapes = shapes,
              type_catalog = self.type_catalog
            }
          )

          for _, validation_error in ipairs(shape_errors) do table.insert(errors, validation_error) end
        end
      end
    end

    for component_name, component_definition in pairs(entity_definition.components or {}) do
      local component_path = entity_path .. ".components." .. component_name

      if type(component_definition) ~= "table" or type(component_definition.type) ~= "string" then
        table.insert(errors, {
          path = component_path .. ".type",
          message = "is required"
        })
      elseif not self.type_catalog:has("component", component_definition.type) then
        table.insert(errors, {
          path = component_path .. ".type",
          message = "unknown component type '" .. tostring(component_definition.type) .. "'"
        })
      else
        local metadata = self.type_catalog:get_definition("component", component_definition.type)

        if metadata ~= nil then
          local component_errors = DefinitionValidator.validate_typed(
            component_definition,
            metadata,
            component_path,
            {
              resource_exists = resource_exists,
              shapes = shapes,
              type_catalog = self.type_catalog
            }
          )

          for _, validation_error in ipairs(component_errors) do table.insert(errors, validation_error) end
        end
      end
    end

    local event_errors = EventDefinitionValidator.validate(
      entity_definition.events,
      entity_path .. ".events",
      {
        resource_exists = resource_exists,
        shapes = shapes,
        type_catalog = self.type_catalog,
        action_exists = function(name)
          return self.event_action_bindings:has(name)
        end
      }
    )

    for _, validation_error in ipairs(event_errors) do table.insert(errors, validation_error) end
  end

  return errors
end

-- Validates a project definition without constructing runtime resources or entities.
function ProjectLoader:validate(definition)
  assert(type(definition) == "table", "project definition must be a table")

  local errors = {}

  local resource_errors = self:_validate_resources(definition.resources, definition.entities)
  for _, validation_error in ipairs(resource_errors) do table.insert(errors, validation_error) end

  local entity_errors = self:_validate_entities(
    definition.entities,
    definition.resources
  )

  for _, validation_error in ipairs(entity_errors) do table.insert(errors, validation_error) end

  return errors
end

-- Builds all runtime entities while preserving project declaration order.
function ProjectLoader:_load_entities(definitions, entity_factory)
  local entities = {}
  local entities_by_id = {}

  for _, definition in ipairs(definitions or {}) do
    local entity = entity_factory:create(definition)

    assert(entities_by_id[entity.id] == nil, "duplicate project entity id: " .. entity.id)

    table.insert(entities, entity)
    entities_by_id[entity.id] = entity
  end

  return entities, entities_by_id
end

-- Loads a validated serializable project definition into runtime Actrune objects.
function ProjectLoader:load(definition)
  assert(type(definition) == "table", "project definition must be a table")

  local validation_errors = self:validate(definition)

  assert(
    DefinitionValidator.is_valid(validation_errors),
    "invalid project definition:\n" .. DefinitionValidator.format_errors(validation_errors)
  )

  local resources = self:_load_resources(definition.resources)
  local entity_factory = self:_create_entity_factory(resources)
  local entities, entities_by_id = self:_load_entities(definition.entities, entity_factory)

  return {
    definition = definition,
    configuration = self.configuration,
    resources = resources,
    entity_factory = entity_factory,
    entities = entities,
    entities_by_id = entities_by_id
  }
end

return ProjectLoader
