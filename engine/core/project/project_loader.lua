local ResourceRegistry = require("engine.core.resources.resource_registry")
local DefinitionRegistry = require("engine.core.definitions.definition_registry")
local DefinitionValidator = require("engine.core.definitions.definition_validator")
local EntityFactory = require("engine.world.entity_factory")
local EventFactory = require("engine.events.event_factory")

local ProjectLoader = {}
ProjectLoader.__index = ProjectLoader

-- Creates a project loader with independent definitions, event factories, and type configuration.
function ProjectLoader.new(options)
  options = options or {}

  local self = setmetatable({}, ProjectLoader)

  self.resource_factories = {}
  self.definitions = DefinitionRegistry.new()
  self.type_catalog = options.type_catalog
  self.event_factory = EventFactory.new(self.definitions)

  return self
end

-- Registers a runtime factory and optional metadata for a serializable resource type.
function ProjectLoader:register_resource_type(type_name, factory, definition)
  assert(type(type_name) == "string", "resource type name must be a string")
  assert(type(factory) == "function", "resource factory must be a function")

  self.resource_factories[type_name] = factory

  if definition ~= nil and not self.definitions:has("resource", type_name) then
    self.definitions:register("resource", type_name, definition)
  end
end

-- Registers a named runtime action available to serialized event commands.
function ProjectLoader:register_event_action(name, callback)
  self.event_factory:register_action(name, callback)
end

-- Builds all resources declared by one project definition.
function ProjectLoader:_load_resources(resource_definitions)
  local registries = {}

  for type_name, definitions in pairs(resource_definitions or {}) do
    local factory = self.resource_factories[type_name]
    assert(factory ~= nil, "unknown project resource type: " .. type_name)

    local registry = ResourceRegistry.new()

    for name, definition in pairs(definitions) do
      registry:register(name, factory(definition))
    end

    registries[type_name] = registry
  end

  return registries
end

-- Creates an entity factory configured with loaded project resources and type registries.
function ProjectLoader:_create_entity_factory(registries)
  local factory = EntityFactory.new(
    self.definitions,
    self.event_factory,
    self.type_catalog
  )

  for type_name, registry in pairs(registries) do
    factory:register_resource_type(type_name, registry)
  end

  return factory
end

-- Validates all project resources against their registered factories and optional metadata.
function ProjectLoader:_validate_resources(resource_definitions)
  local errors = {}

  for type_name, definitions in pairs(resource_definitions or {}) do
    local factory = self.resource_factories[type_name]

    if factory == nil then
      table.insert(errors, {
        path = "resources." .. type_name,
        message = "unknown resource type"
      })
    else
      local metadata = self.definitions:get("resource", type_name)

      if metadata ~= nil then
        for name, definition in pairs(definitions) do
          local resource_errors = DefinitionValidator.validate_typed(
            definition,
            metadata,
            "resources." .. type_name .. "." .. name,
            {}
          )

          for _, validation_error in ipairs(resource_errors) do
            table.insert(errors, validation_error)
          end
        end
      end
    end
  end

  return errors
end

-- Validates all entity shapes and components against their registered metadata.
function ProjectLoader:_validate_entities(entity_definitions, resources)
  local errors = {}

  for entity_index, entity_definition in ipairs(entity_definitions or {}) do
    local entity_path = "entities[" .. entity_index .. "]"

    if type(entity_definition.id) ~= "string" then
      table.insert(errors, {
        path = entity_path .. ".id",
        message = "must be a string"
      })
    end

    for shape_name, shape_definition in pairs(entity_definition.shapes or {}) do
      local shape_path = entity_path .. ".shapes." .. shape_name
      local shape_type = shape_definition.type

      if type(shape_type) ~= "string" then
        table.insert(errors, {
          path = shape_path .. ".type",
          message = "is required"
        })
      else
        local metadata = self.definitions:get("shape", shape_type)

        if metadata == nil then
          table.insert(errors, {
            path = shape_path .. ".type",
            message = "unknown shape type '" .. shape_type .. "'"
          })
        else
          local shape_errors = DefinitionValidator.validate_typed(
            shape_definition,
            metadata,
            shape_path,
            {
              resources = resources,
              shapes = entity_definition.shapes
            }
          )

          for _, validation_error in ipairs(shape_errors) do table.insert(errors, validation_error) end
        end
      end
    end

    for component_name, component_definition in pairs(entity_definition.components or {}) do
      local component_path = entity_path .. ".components." .. component_name
      local component_type = component_definition.type

      if type(component_type) ~= "string" then
        table.insert(errors, {
          path = component_path .. ".type",
          message = "is required"
        })
      else
        local metadata = self.definitions:get("component", component_type)

        if metadata == nil then
          table.insert(errors, {
            path = component_path .. ".type",
            message = "unknown component type '" .. component_type .. "'"
          })
        else
          local component_errors = DefinitionValidator.validate_typed(
            component_definition,
            metadata,
            component_path,
            {
              resources = resources,
              shapes = entity_definition.shapes
            }
          )

          for _, validation_error in ipairs(component_errors) do table.insert(errors, validation_error) end
        end
      end
    end
  end

  return errors
end

-- Validates a project definition before runtime objects are constructed.
function ProjectLoader:validate(definition)
  assert(type(definition) == "table", "project definition must be a table")

  local errors = {}

  local resource_errors = self:_validate_resources(definition.resources)
  for _, validation_error in ipairs(resource_errors) do table.insert(errors, validation_error) end

  local temporary_resources = {}
  if #resource_errors == 0 then temporary_resources = self:_load_resources(definition.resources) end

  self:_create_entity_factory(temporary_resources)

  local entity_errors = self:_validate_entities(definition.entities, temporary_resources)
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
    definitions = self.definitions,
    resources = resources,
    entity_factory = entity_factory,
    entities = entities,
    entities_by_id = entities_by_id
  }
end

return ProjectLoader
