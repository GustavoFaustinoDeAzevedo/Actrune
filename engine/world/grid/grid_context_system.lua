local GridContextSystem = {}
GridContextSystem.__index = GridContextSystem

-- Returns whether a point is inside a polygon represented by flat world coordinates.
local function contains_point(vertices, x, y)
  local inside = false
  local count = #vertices / 2
  local previous = count

  for current = 1, count do
    local current_x = vertices[current * 2 - 1]
    local current_y = vertices[current * 2]
    local previous_x = vertices[previous * 2 - 1]
    local previous_y = vertices[previous * 2]

    local crosses = (current_y > y) ~= (previous_y > y)

    if crosses then
      local intersection_x = (previous_x - current_x) * (y - current_y) / (previous_y - current_y) + current_x
      if x < intersection_x then inside = not inside end
    end

    previous = current
  end

  return inside
end

--- Creates contextual grid resolution with optional world topology support.
---@param world? World World used to resolve equivalent map positions.
function GridContextSystem.new(world)
  return setmetatable({
    world = world,
    areas = {},
    targets = {}
  }, GridContextSystem)
end

-- Registers grid areas and grid-context entities from a loaded project.
function GridContextSystem:add_project(project)
  assert(project ~= nil, "project is required")

  for _, definition in ipairs(project.definition.entities or {}) do
    local entity = project.entities_by_id[definition.id]

    if entity ~= nil then
      local grid_area = entity:get_component("grid_area")
      local grid_context = entity:get_component("grid_context")

      if grid_area ~= nil then
        local shape = entity:get_shape(grid_area:get_shape())

        assert(shape ~= nil, "grid area references missing shape: " .. grid_area:get_shape())
        assert(shape:get_geometry_type() == "polygon", "grid areas currently require polygon shapes")

        table.insert(self.areas, {
          entity = entity,
          area = grid_area,
          shape = shape
        })
      end

      if grid_context ~= nil then
        table.insert(self.targets, {
          entity = entity,
          context = grid_context
        })
      end
    end
  end
end

--- Returns the highest-priority active area containing the entity.
---@param entity Entity Entity whose planar origin is tested.
---@return table|nil selected Registered area entry, or nil outside active areas.
function GridContextSystem:_find_area(entity)
  local selected
  local x, y = entity:get_position()

  for _, entry in ipairs(self.areas) do
    if entry.entity:is_active() then
      local inside
      if self.world ~= nil then
        inside = self.world:shape_contains_point(entry.shape, entry.entity.transform, x, y)
      else
        inside = contains_point(entry.shape:get_world_points(entry.entity.transform), x, y)
      end
      if inside and (selected == nil or entry.area:get_priority() > selected.area:get_priority()) then
        selected = entry
      end
    end
  end
  return selected
end

--- Resolves active targets against active areas without clearing suspended state.
function GridContextSystem:update()
  for _, target in ipairs(self.targets) do
    if target.entity:is_active() then
      local area = self:_find_area(target.entity)
      if area ~= nil then
        target.context:set_metrics(area.area:get_metrics())
      else
        target.context:reset_metrics()
      end
    end
  end
end

return GridContextSystem
