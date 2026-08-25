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

-- Registers all control-updatable components declared by a loaded project.
function ControlSystem:add_project(project)
  assert(project ~= nil, "project is required")

  for _, entity_definition in ipairs(project.definition.entities or {}) do
    local entity = project.entities_by_id[entity_definition.id]

    if entity ~= nil then
      for component_name in pairs(entity_definition.components or {}) do
        local component = entity:get_component(component_name)

        if component ~= nil and type(component.bind_control) == "function" and type(component.update_control) == "function" then
          component:bind_control(self.world, entity)

          table.insert(self.entries, {
            entity = entity,
            component = component
          })
        end
      end
    end
  end
end

-- Updates every registered control-driven component.
function ControlSystem:update(runtime, dt)
  for _, entry in ipairs(self.entries) do entry.component:update_control(runtime, dt) end
end

return ControlSystem
