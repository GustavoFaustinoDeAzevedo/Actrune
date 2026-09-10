---@class EntityPositionPolicy: EntityPositionPolicyFields
local EntityPositionPolicy = {}
EntityPositionPolicy.__index = EntityPositionPolicy

--- Creates a live camera target with optional elevation and map periodicity.
---@param entity Entity Entity followed by the camera.
---@param options? EntityPositionPolicyOptions Position and projection settings.
---@return EntityPositionPolicy policy New position policy.
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
  assert(options.topology == nil or type(options.topology.get_nearest_position) == "function",
    "entity position policy topology must expose get_nearest_position")

  return setmetatable({
    entity = entity,
    offset_x = options.offset_x or 0,
    offset_y = options.offset_y or 0,
    elevation_source = source,
    elevation_scale = scale,
    topology = options.topology
  }, EntityPositionPolicy)
end

--- Resolves the elevated target position nearest to the current camera.
--- Periodic following assumes target-camera separation below half a map period.
---@param context? { camera: table } Required for elevation or periodic following.
---@return number x Visual target X in continuous camera coordinates.
---@return number y Visual target Y in continuous camera coordinates.
function EntityPositionPolicy:resolve(context)
  local x, y = self.entity:get_position()
  x, y = x + self.offset_x, y + self.offset_y
  local camera = context and context.camera

  if self.elevation_source ~= nil and self.elevation_scale ~= 0 then
    assert(camera ~= nil and type(camera.get_rotation) == "function",
      "elevated entity position policy requires context.camera")

    local elevation = self.elevation_source:get_elevation()
    assert(type(elevation) == "number"
      and elevation > -math.huge and elevation < math.huge,
      "entity position policy elevation must be finite")

    local offset = elevation * self.elevation_scale
    local rotation = camera:get_rotation()
    x, y = x + math.sin(rotation) * offset, y - math.cos(rotation) * offset
  end

  if self.topology ~= nil then
    assert(camera ~= nil and type(camera.get_position) == "function",
      "periodic entity position policy requires context.camera")

    local camera_x, camera_y = camera:get_position()
    x, y = self.topology:get_nearest_position(x, y, camera_x, camera_y)
  end

  return x, y
end

return EntityPositionPolicy
