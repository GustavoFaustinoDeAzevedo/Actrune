local SpatialQuery = require("engine.world.spatial.spatial_query")

local ElevationMover = {}
ElevationMover.__index = ElevationMover

-- Creates vertical movement using a fixed horizontal footprint and named body ranges.
function ElevationMover.new(world, entity, options)
  assert(world ~= nil and type(world.query_shape) == "function",
    "elevation mover requires a world exposing query_shape")
  assert(entity ~= nil and type(entity.get_component) == "function",
    "elevation mover requires an entity exposing get_component")
  assert(type(options) == "table", "elevation mover requires options")

  for _, name in ipairs({
    "elevation_component", "source_shape", "target_shape",
    "source_vertical_range", "target_vertical_range"
  }) do
    assert(type(options[name]) == "string" and options[name] ~= "",
      "elevation mover requires a non-empty " .. name)
  end

  local elevation = entity:get_component(options.elevation_component)
  local source_range = entity:get_component(options.source_vertical_range)

  assert(elevation ~= nil and type(elevation.get_offset) == "function"
    and type(elevation.set_offset) == "function",
    "elevation mover requires a mutable elevation component")
  assert(source_range ~= nil and type(source_range.get_bounds) == "function",
    "elevation mover requires a source vertical range")

  return setmetatable({
    world = world,
    entity = entity,
    elevation = elevation,
    source_range = source_range,
    source_shape = options.source_shape,
    target_shape = options.target_shape,
    target_vertical_range = options.target_vertical_range
  }, ElevationMover)
end

-- Moves vertically up to first contact and returns applied displacement and contact entity.
function ElevationMover:try_move(delta)
  assert(type(delta) == "number" and delta > -math.huge and delta < math.huge,
    "elevation displacement must be finite")

  if delta == 0 then return 0, nil end

  local shape = self.entity:get_shape(self.source_shape)
  assert(shape ~= nil, "elevation mover source shape is missing")

  local source_min, source_max = self.source_range:get_bounds(self.entity)
  assert(source_max > source_min, "elevation mover source body must have positive height")

  local candidates = self.world:query_shape(shape, self.entity.transform, self.target_shape)
  local fraction = 1
  local contact = nil

  for _, target in ipairs(candidates) do
    if target ~= self.entity then
      local target_shape = target:get_shape(self.target_shape)

      -- Boundary-only horizontal contact must not prevent sliding vertically.
      if SpatialQuery.polygons_overlap_strict(
            shape, self.entity.transform, target_shape, target.transform
          ) then
        local range = target:get_component(self.target_vertical_range)
        assert(range ~= nil and type(range.get_bounds) == "function",
          "elevation mover target range is missing: " .. target.id)

        local target_min, target_max = range:get_bounds(target)
        assert(target_max > target_min, "elevation mover target body must have positive height")

        local candidate_fraction = nil

        if source_min < target_max and target_min < source_max then
          -- Reject movement from an already penetrating state instead of hiding it.
          candidate_fraction = 0
        elseif delta > 0 and source_max <= target_min then
          candidate_fraction = (target_min - source_max) / delta
        elseif delta < 0 and source_min >= target_max then
          candidate_fraction = (target_max - source_min) / delta
        end

        if candidate_fraction ~= nil and candidate_fraction <= fraction then
          if candidate_fraction < fraction or contact == nil or target.id < contact.id then
            fraction = candidate_fraction
            contact = target
          end
        end
      end
    end
  end

  local applied = delta * fraction
  self.elevation:set_offset(self.elevation:get_offset() + applied)

  return applied, contact
end

-- Attempts to reach an absolute elevation through the existing collision-aware movement.
function ElevationMover:try_move_to(target_elevation)
  assert(type(target_elevation) == "number"
    and target_elevation > -math.huge and target_elevation < math.huge,
    "target elevation must be finite")
  assert(type(self.elevation.get_elevation) == "function",
    "elevation mover requires an elevation source exposing get_elevation")

  local current_elevation = self.elevation:get_elevation()

  return self:try_move(target_elevation - current_elevation)
end

return ElevationMover
