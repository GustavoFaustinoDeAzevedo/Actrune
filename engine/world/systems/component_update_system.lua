local ComponentUpdateSystem = {}
ComponentUpdateSystem.__index = ComponentUpdateSystem

-- Creates a system that discovers, binds, orders, and updates components by capability.
function ComponentUpdateSystem.new(options)
  options = options or {}

  local self = setmetatable({}, ComponentUpdateSystem)

  self.bind_method = options.bind_method
  self.update_method = options.update_method
  self.order_field = options.order_field
  self.bind_context = options.bind_context
  self.entries = {}

  assert(type(self.bind_method) == "string", "component update system bind_method must be a string")
  assert(type(self.update_method) == "string", "component update system update_method must be a string")
  assert(type(self.order_field) == "string", "component update system order_field must be a string")

  return self
end

-- Sorts registered components deterministically by entity, configured order, and component name.
local function compare_entries(a, b)
  if a.entity_index ~= b.entity_index then return a.entity_index < b.entity_index end
  if a.order ~= b.order then return a.order < b.order end
  return a.component_name < b.component_name
end

-- Returns whether a component exposes the capabilities required by this system.
function ComponentUpdateSystem:_accepts(component)
  return component ~= nil
      and type(component[self.bind_method]) == "function"
      and type(component[self.update_method]) == "function"
end

-- Registers all compatible components declared by a loaded project.
function ComponentUpdateSystem:add_project(project)
  assert(project ~= nil, "project is required")

  for entity_index, entity_definition in ipairs(project.definition.entities or {}) do
    local entity = project.entities_by_id[entity_definition.id]

    if entity ~= nil then
      for component_name, component_definition in pairs(entity_definition.components or {}) do
        local component = entity:get_component(component_name)

        if self:_accepts(component) then
          component[self.bind_method](component, self.bind_context, entity)

          table.insert(self.entries, {
            entity = entity,
            entity_index = entity_index,
            component = component,
            component_name = component_name,
            order = component_definition[self.order_field] or 0
          })
        end
      end
    end
  end

  table.sort(self.entries, compare_entries)
end

-- Updates every registered component using the configured capability method.
function ComponentUpdateSystem:update(...)
  for _, entry in ipairs(self.entries) do
    entry.component[self.update_method](entry.component, ...)
  end
end

return ComponentUpdateSystem
