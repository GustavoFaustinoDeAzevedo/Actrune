local Geometry =
    require("engine.world.spatial.geometry")

local SpatialQuery =
    require("engine.world.spatial.spatial_query")

local ContactImpulse =
    require("engine.world.physics.contact_impulse")

local PhysicsWorld = {}
PhysicsWorld.__index = PhysicsWorld

local DEFAULT_MAX_COLLISIONS = 16

-- Creates a coordinated physics simulation over an existing Actrune world.
function PhysicsWorld.new(world, material_resolver, options)
  assert(world ~= nil, "world is required")
  assert(material_resolver ~= nil, "material resolver is required")

  options = options or {}

  local self = setmetatable({}, PhysicsWorld)

  self.world = world
  self.material_resolver = material_resolver
  self.entries = {}

  self.max_collisions = options.max_collisions or DEFAULT_MAX_COLLISIONS

  return self
end

-- Registers an entity and the shape used by the physics simulation.
function PhysicsWorld:add_entity(entity, options)
  assert(entity ~= nil, "entity is required")

  options = options or {}

  assert(
    options.shape ~= nil,
    "physics shape name is required"
  )

  assert(
    entity:get_shape(options.shape) ~= nil,
    "physics shape does not exist"
  )

  self.entries[entity] = {
    entity = entity,
    shape_name = options.shape
  }
end

-- Removes an entity from the physics simulation.
function PhysicsWorld:remove_entity(entity)
  self.entries[entity] = nil
end

-- Returns whether an entity has both velocity and mass components.
local function is_dynamic(entry)
  return entry.entity:get_component("velocity") ~= nil
      and entry.entity:get_component("mass") ~= nil
end

-- Applies configured acceleration to every dynamic entity.
local function apply_accelerations(entries, dt)
  for _, entry in pairs(entries) do
    if is_dynamic(entry) then
      local acceleration =
          entry.entity:get_component(
            "acceleration"
          )

      if acceleration ~= nil then
        local change_x, change_y = acceleration:get_velocity_change(dt)

        local velocity = entry.entity:get_component("velocity")

        velocity:add(change_x, change_y)
      end
    end
  end
end

-- Calculates an entity's displacement over the provided time interval.
local function get_displacement(entry, dt)
  if not is_dynamic(entry) then
    return 0, 0
  end

  local velocity = entry.entity:get_component("velocity")

  return velocity:get_displacement(dt)
end

-- Advances every dynamic entity by the provided time interval.
local function advance_entries(entries, dt)
  for _, entry in pairs(entries) do
    if is_dynamic(entry) then
      local dx, dy =
          get_displacement(
            entry,
            dt
          )

      entry.entity.transform:translate(
        dx,
        dy
      )
    end
  end
end

-- Finds the earliest simultaneous contacts among all registered entities.
local function find_earliest_contacts(
    entries,
    remaining_time
)
  local list = {}

  for _, entry in pairs(entries) do
    table.insert(list, entry)
  end

  local earliest_fraction = nil
  local contacts = {}

  for index_a = 1, #list - 1 do
    local entry_a = list[index_a]

    for index_b = index_a + 1, #list do
      local entry_b = list[index_b]

      local move_a_x, move_a_y =
          get_displacement(
            entry_a,
            remaining_time
          )

      local move_b_x, move_b_y =
          get_displacement(
            entry_b,
            remaining_time
          )

      local relative_x = move_a_x - move_b_x
      local relative_y = move_a_y - move_b_y

      if math.abs(relative_x) > Geometry.EPSILON
          or math.abs(relative_y) > Geometry.EPSILON
      then
        local shape_a = entry_a.entity:get_shape(entry_a.shape_name)
        local shape_b = entry_b.entity:get_shape(entry_b.shape_name)

        local hit =
            SpatialQuery.sweep_polygons(
              shape_a,
              entry_a.entity.transform,
              relative_x,
              relative_y,
              shape_b,
              entry_b.entity.transform
            )

        if hit ~= nil then
          if earliest_fraction == nil or hit.fraction < earliest_fraction - Geometry.EPSILON
          then
            earliest_fraction = hit.fraction
            contacts = {}
          end

          if math.abs(hit.fraction - earliest_fraction) <= Geometry.EPSILON
          then
            local contact_x = hit.point_x + move_b_x * hit.fraction
            local contact_y = hit.point_y + move_b_y * hit.fraction
            table.insert(
              contacts,
              {
                source = entry_a,
                target = entry_b,

                source_shape = shape_a,
                target_shape = shape_b,

                normal_x = hit.normal_x,
                normal_y = hit.normal_y,

                point_x = contact_x,
                point_y = contact_y,

                fraction = hit.fraction
              }
            )
          end
        end
      end
    end
  end

  return earliest_fraction, contacts
end

-- Resolves one contact using the dynamic state and materials of both entities.
function PhysicsWorld:_resolve_contact(contact)
  local source_entity = contact.source.entity
  local target_entity = contact.target.entity
  local source_velocity = source_entity:get_component("velocity")
  local source_mass = source_entity:get_component("mass")
  local target_velocity = target_entity:get_component("velocity")
  local target_mass = target_entity:get_component("mass")
  local properties =
      self.material_resolver:resolve(
        contact.source_shape:get_material(),
        contact.target_shape:get_material()
      )

  if source_velocity ~= nil
      and source_mass ~= nil
  then
    ContactImpulse.apply_pair(
      source_velocity,
      source_mass,
      target_velocity,
      target_mass,
      contact.normal_x,
      contact.normal_y,
      properties
    )

    return
  end

  if target_velocity ~= nil
      and target_mass ~= nil
  then
    ContactImpulse.apply_pair(
      target_velocity,
      target_mass,
      nil,
      nil,
      -contact.normal_x,
      -contact.normal_y,
      properties
    )
  end
end

-- Advances all registered physical entities through one coordinated simulation step.
function PhysicsWorld:update(dt)
  apply_accelerations(
    self.entries,
    dt
  )

  local remaining_time = dt
  local collision_count = 0

  while remaining_time > Geometry.EPSILON do
    local fraction, contacts =
        find_earliest_contacts(
          self.entries,
          remaining_time
        )

    if fraction == nil then
      advance_entries(
        self.entries,
        remaining_time
      )

      break
    end

    local consumed_time =
        remaining_time
        * Geometry.clamp(
          fraction,
          0,
          1
        )

    advance_entries(
      self.entries,
      consumed_time
    )

    remaining_time = remaining_time - consumed_time

    for _, contact in ipairs(contacts) do
      self:_resolve_contact(contact)
    end

    collision_count = collision_count + #contacts

    if collision_count >= self.max_collisions then
      break
    end
  end
end

return PhysicsWorld
