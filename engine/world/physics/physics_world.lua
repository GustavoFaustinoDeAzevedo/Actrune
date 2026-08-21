local Geometry =
    require("engine.world.spatial.geometry")

local SpatialQuery =
    require("engine.world.spatial.spatial_query")

local ContactImpulse =
    require("engine.world.physics.contact_impulse")

local PhysicsWorld = {}
PhysicsWorld.__index = PhysicsWorld

local DEFAULT_MAX_COLLISIONS = 16
local DEFAULT_CONTACT_ITERATIONS = 4
local CONTACT_SEPARATION = 0.0001
local DEFAULT_RESTITUTION_THRESHOLD = 0
local MIN_TIME_ADVANCE = 0.000001

-- Creates a coordinated physics simulation over an existing Actrune world.
function PhysicsWorld.new(world, material_resolver, options)
  assert(world ~= nil, "world is required")
  assert(material_resolver ~= nil, "material resolver is required")

  options = options or {}

  local self = setmetatable({}, PhysicsWorld)

  self.world = world
  self.material_resolver = material_resolver
  self.entries = {}
  self.entry_by_entity = {}
  self.last_collision_iterations = 0
  self.last_broadphase_pairs = 0
  self.last_narrowphase_tests = 0
  self.contact_iterations = options.contact_iterations or DEFAULT_CONTACT_ITERATIONS
  self.max_collisions = options.max_collisions or DEFAULT_MAX_COLLISIONS
  self.restitution_threshold = options.restitution_threshold or DEFAULT_RESTITUTION_THRESHOLD

  return self
end

-- Returns whether an entity has both velocity and mass components.
local function is_dynamic(entry)
  return entry.entity:get_component("velocity") ~= nil
      and entry.entity:get_component("mass") ~= nil
end

-- Returns the inverse mass of a dynamic entry or zero for a static entry.
local function get_inverse_mass(entry)
  if not is_dynamic(entry) then return 0 end
  return entry.entity:get_component("mass"):get_inverse()
end

-- Returns a body's linear velocity or zero when the body is static.
local function get_velocity(entry)
  if not is_dynamic(entry) then return 0, 0 end
  return entry.entity:get_component("velocity"):get()
end

-- Applies configured acceleration to every dynamic entity in simulation order.
local function apply_accelerations(entries, dt)
  for _, entry in ipairs(entries) do
    if is_dynamic(entry) then
      local acceleration = entry.entity:get_component("acceleration")

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

-- Advances every dynamic entity through the provided linear time interval.
local function advance_entries(entries, dt)
  for _, entry in ipairs(entries) do
    if is_dynamic(entry) then
      local dx, dy = get_displacement(entry, dt)
      entry.entity.transform:translate(dx, dy)
    end
  end
end

-- Calculates the swept world-space AABB of an entry over the provided displacement.
local function get_swept_bounds(entry, move_x, move_y)
  local shape = entry.entity:get_shape(entry.shape_name)
  local points = shape:get_world_points(entry.entity.transform)

  local min_x, max_x = points[1], points[1]
  local min_y, max_y = points[2], points[2]

  for index = 3, #points, 2 do
    local x = points[index]
    local y = points[index + 1]

    if x < min_x then min_x = x end
    if x > max_x then max_x = x end
    if y < min_y then min_y = y end
    if y > max_y then max_y = y end
  end

  if move_x < 0 then min_x = min_x + move_x else max_x = max_x + move_x end
  if move_y < 0 then min_y = min_y + move_y else max_y = max_y + move_y end

  return {
    min_x = min_x,
    min_y = min_y,
    max_x = max_x,
    max_y = max_y
  }
end

-- Returns whether two swept AABBs can possibly overlap during the interval.
local function bounds_overlap(a, b)
  return a.max_x >= b.min_x and a.min_x <= b.max_x and a.max_y >= b.min_y and a.min_y <= b.max_y
end

-- Finds the earliest simultaneous contacts among broad-phase candidate pairs.
local function find_earliest_contacts(entries, remaining_time)
  local earliest_fraction = nil
  local contacts = {}
  local states = {}
  local broadphase_pairs = 0
  local narrowphase_tests = 0

  for index, entry in ipairs(entries) do
    local move_x, move_y = get_displacement(entry, remaining_time)

    states[index] = {
      entry = entry,
      move_x = move_x,
      move_y = move_y,
      bounds = get_swept_bounds(entry, move_x, move_y)
    }
  end

  for index_a = 1, #states - 1 do
    local state_a = states[index_a]

    for index_b = index_a + 1, #states do
      local state_b = states[index_b]

      broadphase_pairs = broadphase_pairs + 1

      local relative_x = state_a.move_x - state_b.move_x
      local relative_y = state_a.move_y - state_b.move_y

      if (math.abs(relative_x) > Geometry.EPSILON or math.abs(relative_y) > Geometry.EPSILON)
          and bounds_overlap(state_a.bounds, state_b.bounds) then
        narrowphase_tests = narrowphase_tests + 1

        local entry_a = state_a.entry
        local entry_b = state_b.entry
        local shape_a = entry_a.entity:get_shape(entry_a.shape_name)
        local shape_b = entry_b.entity:get_shape(entry_b.shape_name)

        local hit = SpatialQuery.sweep_polygons(
          shape_a,
          entry_a.entity.transform,
          relative_x,
          relative_y,
          shape_b,
          entry_b.entity.transform
        )

        if hit ~= nil then
          if earliest_fraction == nil or hit.fraction < earliest_fraction - Geometry.EPSILON then
            earliest_fraction = hit.fraction
            contacts = {}
          end

          if math.abs(hit.fraction - earliest_fraction) <= Geometry.EPSILON then
            table.insert(contacts, {
              source = entry_a,
              target = entry_b,
              source_shape = shape_a,
              target_shape = shape_b,
              normal_x = hit.normal_x,
              normal_y = hit.normal_y,
              point_x = hit.point_x + state_b.move_x * hit.fraction,
              point_y = hit.point_y + state_b.move_y * hit.fraction,
              fraction = hit.fraction
            })
          end
        end
      end
    end
  end

  return earliest_fraction, contacts, broadphase_pairs, narrowphase_tests
end

-- Registers an entity in deterministic insertion order for physics simulation.
function PhysicsWorld:add_entity(entity, options)
  assert(entity ~= nil, "entity is required")

  options = options or {}

  assert(options.shape ~= nil, "physics shape name is required")
  assert(entity:get_shape(options.shape) ~= nil, "physics shape does not exist")
  assert(self.entry_by_entity[entity] == nil, "entity is already registered in physics world")

  local entry = {
    entity = entity,
    shape_name = options.shape
  }

  table.insert(self.entries, entry)
  self.entry_by_entity[entity] = entry
end

-- Removes an entity while preserving the order of the remaining physics entries.
function PhysicsWorld:remove_entity(entity)
  local entry = self.entry_by_entity[entity]
  if entry == nil then return false end

  for index, candidate in ipairs(self.entries) do
    if candidate == entry then
      table.remove(self.entries, index)
      break
    end
  end

  self.entry_by_entity[entity] = nil
  return true
end

-- Resolves material properties while suppressing restitution for low-speed contacts.
function PhysicsWorld:_get_contact_properties(contact, normal_x, normal_y, source_entry, target_entry)
  local properties = self.material_resolver:resolve(
    contact.source_shape:get_material(),
    contact.target_shape:get_material()
  )

  local source_x, source_y = get_velocity(source_entry)
  local target_x, target_y = get_velocity(target_entry)
  local relative_x = source_x - target_x
  local relative_y = source_y - target_y
  local normal_velocity = Geometry.dot(relative_x, relative_y, normal_x, normal_y)

  if normal_velocity < 0 and -normal_velocity < self.restitution_threshold then
    properties.restitution = 0
  end

  return properties
end

-- Applies a relative separation vector according to both entities' inverse masses.
function PhysicsWorld:_apply_pair_separation(entry_a, entry_b, separation_x, separation_y)
  local inverse_mass_a = get_inverse_mass(entry_a)
  local inverse_mass_b = get_inverse_mass(entry_b)
  local inverse_mass_sum = inverse_mass_a + inverse_mass_b

  if inverse_mass_sum <= Geometry.EPSILON then return false end

  local share_a = inverse_mass_a / inverse_mass_sum
  local share_b = inverse_mass_b / inverse_mass_sum

  entry_a.entity.transform:translate(separation_x * share_a, separation_y * share_a)
  entry_b.entity.transform:translate(-separation_x * share_b, -separation_y * share_b)

  return true
end

-- Recovers a pair that already begins the simulation interval overlapping.
function PhysicsWorld:_recover_overlap(entry_a, entry_b)
  local shape_a = entry_a.entity:get_shape(entry_a.shape_name)
  local shape_b = entry_b.entity:get_shape(entry_b.shape_name)

  local separation = SpatialQuery.find_polygon_separation(
    shape_a,
    entry_a.entity.transform,
    shape_b,
    entry_b.entity.transform
  )

  if separation == nil then return false end

  return self:_apply_pair_separation(entry_a, entry_b, separation.x, separation.y)
end

-- Recovers registered entity pairs that begin a simulation interval overlapping.
function PhysicsWorld:_recover_overlaps()
  for index_a = 1, #self.entries - 1 do
    local entry_a = self.entries[index_a]

    for index_b = index_a + 1, #self.entries do
      local entry_b = self.entries[index_b]

      if is_dynamic(entry_a) or is_dynamic(entry_b) then
        self:_recover_overlap(entry_a, entry_b)
      end
    end
  end
end

-- Separates two contacting entities by a tiny mass-weighted distance.
function PhysicsWorld:_separate_contact(contact)
  local source_inverse_mass = get_inverse_mass(contact.source)
  local target_inverse_mass = get_inverse_mass(contact.target)
  local inverse_mass_sum = source_inverse_mass + target_inverse_mass

  if inverse_mass_sum <= Geometry.EPSILON then return end

  local source_share = source_inverse_mass / inverse_mass_sum
  local target_share = target_inverse_mass / inverse_mass_sum

  contact.source.entity.transform:translate(
    contact.normal_x * CONTACT_SEPARATION * source_share,
    contact.normal_y * CONTACT_SEPARATION * source_share
  )

  contact.target.entity.transform:translate(
    -contact.normal_x * CONTACT_SEPARATION * target_share,
    -contact.normal_y * CONTACT_SEPARATION * target_share
  )
end

-- Resolves simultaneous contacts through repeated sequential impulse passes.
function PhysicsWorld:_resolve_contacts(contacts)
  for _ = 1, self.contact_iterations do
    for _, contact in ipairs(contacts) do
      self:_resolve_contact(contact)
    end
  end

  for _, contact in ipairs(contacts) do
    self:_separate_contact(contact)
  end
end

-- Resolves one contact using the dynamic state and materials of both entities.
function PhysicsWorld:_resolve_contact(contact)
  local source_dynamic = is_dynamic(contact.source)
  local target_dynamic = is_dynamic(contact.target)

  if source_dynamic then
    local source_velocity = contact.source.entity:get_component("velocity")
    local source_mass = contact.source.entity:get_component("mass")

    local target_velocity = nil
    local target_mass = nil

    if target_dynamic then
      target_velocity = contact.target.entity:get_component("velocity")
      target_mass = contact.target.entity:get_component("mass")
    end

    local properties = self:_get_contact_properties(
      contact,
      contact.normal_x,
      contact.normal_y,
      contact.source,
      contact.target
    )

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

  if target_dynamic then
    local target_velocity = contact.target.entity:get_component("velocity")
    local target_mass = contact.target.entity:get_component("mass")

    local properties = self:_get_contact_properties(
      contact,
      -contact.normal_x,
      -contact.normal_y,
      contact.target,
      contact.source
    )

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
  self.last_collision_iterations = 0
  self.last_broadphase_pairs = 0
  self.last_narrowphase_tests = 0


  apply_accelerations(self.entries, dt)
  self:_recover_overlaps()

  local remaining_time = dt
  local collision_count = 0


  while remaining_time > Geometry.EPSILON do
    self.last_collision_iterations = self.last_collision_iterations + 1

    local fraction, contacts, broadphase_pairs, narrowphase_tests = find_earliest_contacts(self.entries, remaining_time)

    self.last_broadphase_pairs = self.last_broadphase_pairs + broadphase_pairs
    self.last_narrowphase_tests = self.last_narrowphase_tests + narrowphase_tests

    if fraction == nil then
      advance_entries(self.entries, remaining_time)
      break
    end

    local consumed_time = remaining_time * Geometry.clamp(fraction, 0, 1)

    advance_entries(self.entries, consumed_time)
    remaining_time = remaining_time - consumed_time

    self:_resolve_contacts(contacts)

    collision_count = collision_count + #contacts

    if consumed_time <= MIN_TIME_ADVANCE then break end
    if collision_count >= self.max_collisions then break end
  end
end

return PhysicsWorld
