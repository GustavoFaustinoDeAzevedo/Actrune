local EntityPositionPolicy = {}
EntityPositionPolicy.__index = EntityPositionPolicy

-- Creates an entity position target with optional orthographic elevation tracking.
function EntityPositionPolicy.new(entity, options)
  options = options or {}

  assert(entity ~= nil and type(entity.get_position) == "function",
    "entity position policy target must expose get_position")

  local source = options.elevation_source
  local scale = options.elevation_scale or 1

  assert(source == nil or type(source.get_elevation) == "function",
    "entity position policy elevation source must expose get_elevation")
  assert(type(scale) == "number" and scale >= 0 and scale < math.huge,
    "entity position policy elevation scale must be finite and non-negative")

  return setmetatable({
    entity = entity,
    offset_x = options.offset_x or 0,
    offset_y = options.offset_y or 0,
    elevation_source = source,
    elevation_scale = scale
  }, EntityPositionPolicy)
end

-- Resolves the visual target position using the camera's current orientation.
function EntityPositionPolicy:resolve(context)
  local x, y = self.entity:get_position()
  x, y = x + self.offset_x, y + self.offset_y

  if self.elevation_source == nil or self.elevation_scale == 0 then return x, y end

  local camera = context and context.camera
  assert(camera ~= nil and type(camera.get_rotation) == "function",
    "elevated entity position policy requires context.camera")

  local elevation = self.elevation_source:get_elevation()
  assert(type(elevation) == "number"
    and elevation > -math.huge and elevation < math.huge,
    "entity position policy elevation must be finite")

  local offset = elevation * self.elevation_scale
  local rotation = camera:get_rotation()

  -- Convert screen-up displacement to world axes without changing the entity.
  return x + math.sin(rotation) * offset,
      y - math.cos(rotation) * offset
end

return EntityPositionPolicy
