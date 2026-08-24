local Geometry = require("engine.world.spatial.geometry")
local SpatialQuery = require("engine.world.spatial.spatial_query")
local ContactImpulse = require("engine.world.physics.contact_impulse")
local PhysicsStats = require("engine.world.physics.physics_stats")

local PhysicsWorld = {}
PhysicsWorld.__index = PhysicsWorld

local DEFAULT_MAX_COLLISIONS = 16
local DEFAULT_CONTACT_ITERATIONS = 8
local DEFAULT_RESTITUTION_THRESHOLD = 0
local DEFAULT_CCD_VELOCITY_EPSILON = 0.1
local DEFAULT_CONTACT_REFRESH_DISTANCE = 0.1
local DEFAULT_CONTACT_REFRESH_THRESHOLD = 0.25
local DEFAULT_CONTACT_REFRESH_ANGLE_THRESHOLD = math.rad(2)


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
  self.contact_cache = {}
  self.contact_by_pair = {}
  self.stats = PhysicsStats.new()

  self.contact_iterations = options.contact_iterations or DEFAULT_CONTACT_ITERATIONS
  self.max_collisions = options.max_collisions or DEFAULT_MAX_COLLISIONS
  self.restitution_threshold = options.restitution_threshold or DEFAULT_RESTITUTION_THRESHOLD
  self.ccd_velocity_epsilon = options.ccd_velocity_epsilon or DEFAULT_CCD_VELOCITY_EPSILON
  self.contact_refresh_distance = options.contact_refresh_distance or DEFAULT_CONTACT_REFRESH_DISTANCE
  self.contact_refresh_threshold = options.contact_refresh_threshold or DEFAULT_CONTACT_REFRESH_THRESHOLD
  self.contact_refresh_angle_threshold = options.contact_refresh_angle_threshold or
      DEFAULT_CONTACT_REFRESH_ANGLE_THRESHOLD

  return self
end

-- Returns whether an entity has both velocity and mass components.
local function is_dynamic(entry)
  return entry.entity:get_component("velocity") ~= nil and entry.entity:get_component("mass") ~= nil
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

-- Returns the shortest signed difference between two angles.
local function angle_difference(a, b)
  return (a - b + math.pi) % (2 * math.pi) - math.pi
end

-- Stores the relative transform used by the latest contact geometry refresh.
local function store_contact_refresh_transform(contact)
  contact.refresh_x = contact.source.entity.transform.x - contact.target.entity.transform.x
  contact.refresh_y = contact.source.entity.transform.y - contact.target.entity.transform.y
  contact.refresh_rotation = contact.source.entity.transform.rotation - contact.target.entity.transform.rotation
end

-- Returns whether relative translation or rotation requires refreshed contact geometry.
local function should_refresh_contact(contact, distance_threshold, angle_threshold)
  if contact.refresh_x == nil or contact.refresh_y == nil or contact.refresh_rotation == nil then return true end

  local source_transform = contact.source.entity.transform
  local target_transform = contact.target.entity.transform
  local relative_x = source_transform.x - target_transform.x
  local relative_y = source_transform.y - target_transform.y
  local relative_rotation = source_transform.rotation - target_transform.rotation
  local difference_x = relative_x - contact.refresh_x
  local difference_y = relative_y - contact.refresh_y
  local difference_rotation = angle_difference(relative_rotation, contact.refresh_rotation)

  if difference_x * difference_x + difference_y * difference_y >= distance_threshold * distance_threshold then return true end
  return math.abs(difference_rotation) >= angle_threshold
end

-- Applies configured acceleration to every dynamic entity in simulation order.
local function apply_accelerations(entries, dt)
  for _, entry in ipairs(entries) do
    if is_dynamic(entry) then
      local acceleration = entry.entity:get_component("acceleration")

      if acceleration ~= nil then
        local change_x, change_y = acceleration:get_velocity_change(dt)
        entry.entity:get_component("velocity"):add(change_x, change_y)
      end
    end
  end
end

-- Calculates an entity's displacement over the provided time interval.
local function get_displacement(entry, dt)
  if not is_dynamic(entry) then return 0, 0 end
  return entry.entity:get_component("velocity"):get_displacement(dt)
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

-- Returns whether a pair already belongs to the persistent contact cache.
local function is_cached_pair(contact_by_pair, entry_a, entry_b)
  local contacts = contact_by_pair[entry_a]
  return contacts ~= nil and contacts[entry_b] ~= nil
end

-- Finds the earliest simultaneous contacts among uncached broad-phase candidate pairs.
local function find_earliest_contacts(entries, remaining_time, velocity_epsilon, contact_by_pair)
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
      local entry_a = state_a.entry
      local entry_b = state_b.entry

      broadphase_pairs = broadphase_pairs + 1

      if not is_cached_pair(contact_by_pair, entry_a, entry_b) then
        local relative_x = state_a.move_x - state_b.move_x
        local relative_y = state_a.move_y - state_b.move_y

        if (math.abs(relative_x) > Geometry.EPSILON or math.abs(relative_y) > Geometry.EPSILON)
            and bounds_overlap(state_a.bounds, state_b.bounds) then
          narrowphase_tests = narrowphase_tests + 1

          local shape_a = entry_a.entity:get_shape(entry_a.shape_name)
          local shape_b = entry_b.entity:get_shape(entry_b.shape_name)

          local hit = SpatialQuery.sweep_polygons(
            shape_a, entry_a.entity.transform,
            relative_x, relative_y,
            shape_b, entry_b.entity.transform
          )

          if hit ~= nil then
            local normal_displacement = Geometry.dot(relative_x, relative_y, hit.normal_x, hit.normal_y)
            local closing_speed = -normal_displacement / remaining_time
            if closing_speed <= velocity_epsilon then hit = nil end
          end

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
  end

  return earliest_fraction, contacts, broadphase_pairs, narrowphase_tests
end



-- Returns the optional angular state used by the contact impulse solver.
local function get_angular_state(entry)
  if not is_dynamic(entry) then return nil end

  local entity = entry.entity
  local angular_velocity = entity:get_component("angular_velocity")
  local inertia = entity:get_component("inertia")

  assert(
    (angular_velocity == nil) == (inertia == nil),
    "angular velocity and inertia must both be present or absent"
  )

  if angular_velocity == nil then return nil end

  return {
    angular_velocity = angular_velocity,
    inertia = inertia,
    center_x = entity.transform.x,
    center_y = entity.transform.y
  }
end

-- Returns the statistics collected during the most recent physics step.
function PhysicsWorld:get_stats()
  return self.stats
end

-- Returns a cached contact for an unordered entity pair.
function PhysicsWorld:_get_cached_contact(entry_a, entry_b)
  local contacts = self.contact_by_pair[entry_a]
  if contacts == nil then return nil end
  return contacts[entry_b]
end

-- Indexes a cached contact in both pair directions.
function PhysicsWorld:_index_cached_contact(contact)
  self.contact_by_pair[contact.source] = self.contact_by_pair[contact.source] or {}
  self.contact_by_pair[contact.target] = self.contact_by_pair[contact.target] or {}

  self.contact_by_pair[contact.source][contact.target] = contact
  self.contact_by_pair[contact.target][contact.source] = contact
end

-- Removes a cached contact and its pair index.
function PhysicsWorld:_remove_cached_contact(index)
  local contact = self.contact_cache[index]
  if contact == nil then return end

  if self.contact_by_pair[contact.source] ~= nil then
    self.contact_by_pair[contact.source][contact.target] = nil
    if next(self.contact_by_pair[contact.source]) == nil then self.contact_by_pair[contact.source] = nil end
  end

  if self.contact_by_pair[contact.target] ~= nil then
    self.contact_by_pair[contact.target][contact.source] = nil
    if next(self.contact_by_pair[contact.target]) == nil then self.contact_by_pair[contact.target] = nil end
  end

  table.remove(self.contact_cache, index)
end

-- Returns whether a pair already has a persistent cached contact.
function PhysicsWorld:_has_cached_contact(entry_a, entry_b)
  return self:_get_cached_contact(entry_a, entry_b) ~= nil
end

-- Refreshes cached geometry only after meaningful relative movement.
function PhysicsWorld:_refresh_contact_cache()
  for index = #self.contact_cache, 1, -1 do
    local contact = self.contact_cache[index]

    if self.entry_by_entity[contact.source.entity] ~= contact.source
        or self.entry_by_entity[contact.target.entity] ~= contact.target then
      self:_remove_cached_contact(index)
    elseif not SpatialQuery.polygons_intersect(
          contact.source_shape,
          contact.source.entity.transform,
          contact.target_shape,
          contact.target.entity.transform
        ) then
      self:_remove_cached_contact(index)
    elseif should_refresh_contact(
          contact,
          self.contact_refresh_threshold,
          self.contact_refresh_angle_threshold
        ) then
      local hit = SpatialQuery.find_polygon_contact(
        contact.source_shape,
        contact.source.entity.transform,
        contact.target_shape,
        contact.target.entity.transform,
        self.contact_refresh_distance
      )

      if hit ~= nil then
        contact.normal_x = hit.normal_x
        contact.normal_y = hit.normal_y
        contact.point_x = hit.point_x
        contact.point_y = hit.point_y
        contact.fraction = 0
        store_contact_refresh_transform(contact)
      end
    end
  end
end

-- Adds new CCD contacts to the persistent contact cache or refreshes existing ones.
function PhysicsWorld:_cache_contacts(contacts)
  for _, contact in ipairs(contacts) do
    local cached = self:_get_cached_contact(contact.source, contact.target)

    if cached ~= nil then
      cached.source_shape = contact.source_shape
      cached.target_shape = contact.target_shape
      cached.normal_x = contact.normal_x
      cached.normal_y = contact.normal_y
      cached.point_x = contact.point_x
      cached.point_y = contact.point_y
      cached.fraction = contact.fraction
      store_contact_refresh_transform(cached)
    else
      store_contact_refresh_transform(contact)
      table.insert(self.contact_cache, contact)
      self:_index_cached_contact(contact)
    end
  end
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

  for index = #self.contact_cache, 1, -1 do
    local contact = self.contact_cache[index]
    if contact.source == entry or contact.target == entry then self:_remove_cached_contact(index) end
  end

  return true
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

-- Recovers uncached entity pairs that begin a simulation interval overlapping.
function PhysicsWorld:_recover_overlaps()
  for index_a = 1, #self.entries - 1 do
    local entry_a = self.entries[index_a]

    for index_b = index_a + 1, #self.entries do
      local entry_b = self.entries[index_b]

      if (is_dynamic(entry_a) or is_dynamic(entry_b))
          and not self:_has_cached_contact(entry_a, entry_b) then
        self:_recover_overlap(entry_a, entry_b)
      end
    end
  end
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

  if normal_velocity < 0 and -normal_velocity < self.restitution_threshold then properties.restitution = 0 end

  return properties
end

-- Resolves one contact using linear state and optional angular response.
function PhysicsWorld:_resolve_contact(contact, use_angular)
  local source_entity = contact.source.entity
  local target_entity = contact.target.entity
  local source_dynamic = is_dynamic(contact.source)
  local target_dynamic = is_dynamic(contact.target)

  if source_dynamic then
    local source_velocity = source_entity:get_component("velocity")
    local source_mass = source_entity:get_component("mass")
    local target_velocity = nil
    local target_mass = nil

    if target_dynamic then
      target_velocity = target_entity:get_component("velocity")
      target_mass = target_entity:get_component("mass")
    end

    local properties = self:_get_contact_properties(
      contact,
      contact.normal_x,
      contact.normal_y,
      contact.source,
      contact.target
    )

    local rotational = nil

    if use_angular then
      rotational = {
        point_x = contact.point_x,
        point_y = contact.point_y,
        source = get_angular_state(contact.source),
        target = get_angular_state(contact.target)
      }
    end

    ContactImpulse.apply_pair(
      source_velocity,
      source_mass,
      target_velocity,
      target_mass,
      contact.normal_x,
      contact.normal_y,
      properties,
      rotational
    )

    return
  end

  if target_dynamic then
    local properties = self:_get_contact_properties(
      contact,
      -contact.normal_x,
      -contact.normal_y,
      contact.target,
      contact.source
    )

    local rotational = nil

    if use_angular then
      rotational = {
        point_x = contact.point_x,
        point_y = contact.point_y,
        source = get_angular_state(contact.target),
        target = nil
      }
    end

    ContactImpulse.apply_pair(
      target_entity:get_component("velocity"),
      target_entity:get_component("mass"),
      nil,
      nil,
      -contact.normal_x,
      -contact.normal_y,
      properties,
      rotational
    )
  end
end

-- Resolves simultaneous contacts through repeated sequential impulse passes.
function PhysicsWorld:_resolve_contacts(contacts, use_angular)
  for _ = 1, self.contact_iterations do
    for _, contact in ipairs(contacts) do self:_resolve_contact(contact, use_angular) end
  end
end

-- Advances all registered physical entities through one coordinated simulation step.
function PhysicsWorld:update(dt)
  self.stats:reset()

  apply_accelerations(self.entries, dt)

  self:_refresh_contact_cache()
  self:_recover_overlaps()

  if #self.contact_cache > 0 then self:_resolve_contacts(self.contact_cache, false) end

  local remaining_time = dt
  local collision_count = 0

  while remaining_time > Geometry.EPSILON do
    self.stats:record_collision_iteration()

    local fraction, contacts, broadphase_pairs, narrowphase_tests =
        find_earliest_contacts(
          self.entries,
          remaining_time,
          self.ccd_velocity_epsilon,
          self.contact_by_pair
        )

    self.stats:record_collision_search(broadphase_pairs, narrowphase_tests)

    if fraction == nil then
      advance_entries(self.entries, remaining_time)
      break
    end

    local consumed_time = remaining_time * Geometry.clamp(fraction, 0, 1)

    advance_entries(self.entries, consumed_time)
    remaining_time = remaining_time - consumed_time

    -- New impacts may produce angular response because the impulse is instantaneous.
    self:_resolve_contacts(contacts, true)

    -- Persistent contacts remain linear until physical rotation is integrated.
    self:_cache_contacts(contacts)
    self:_resolve_contacts(self.contact_cache, false)

    collision_count = collision_count + #contacts
    if collision_count >= self.max_collisions then break end
  end

  self.stats:set_cached_contacts(#self.contact_cache)
end

return PhysicsWorld
