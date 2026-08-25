local ControlSystem = {}
ControlSystem.__index = ControlSystem

-- Creates a control system bound to one Actrune spatial world.
function ControlSystem.new(world)
  assert(world ~= nil, "control system requires a world")

  return setmetatable({
    world = world,
    entries = {}
  }, ControlSystem)
end

-- Sorts control components deterministically by entity, configured order, and component name.
local function compare_entries(a, b)
  if a.entity_index ~= b.entity_index then return a.entity_index < b.entity_index end
  if a.control_order ~= b.control_order then return a.control_order < b.control_order end
  return a.component_name < b.component_name
end

-- Registers all control-updatable components declared by a loaded project.
function ControlSystem:add_project(project)
  assert(project ~= nil, "project is required")

  for entity_index, entity_definition in ipairs(project.definition.entities or {}) do
    local entity = project.entities_by_id[entity_definition.id]

    if entity ~= nil then
      for component_name, component_definition in pairs(entity_definition.components or {}) do
        local component = entity:get_component(component_name)

        if component ~= nil and type(component.bind_control) == "function" and type(component.update_control) == "function" then
          component:bind_control(self.world, entity)

          table.insert(self.entries, {
            entity = entity,
            entity_index = entity_index,
            component = component,
            component_name = component_name,
            control_order = component_definition.control_order or 0
          })
        end
      end
    end
  end

  table.sort(self.entries, compare_entries)
end

-- Updates every registered control-driven component in deterministic order.
function ControlSystem:update(runtime, dt)
  for _, entry in ipairs(self.entries) do entry.component:update_control(runtime, dt) end
end

return ControlSystem
