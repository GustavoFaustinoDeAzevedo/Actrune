local PerspectiveProjection = {}
PerspectiveProjection.__index = PerspectiveProjection

-- Reuses exact projection factors until their source parameters change.
function PerspectiveProjection:_get_projection_factors()
  local rotation = self:get_rotation()
  local fov = self.horizontal_fov

  if self.cached_rotation ~= rotation then
    self.cached_forward_x = math.cos(rotation)
    self.cached_forward_y = math.sin(rotation)
    self.cached_rotation = rotation
  end

  if self.cached_horizontal_fov ~= fov then
    self.cached_half_fov_tangent = math.tan(fov * 0.5)
    self.cached_horizontal_fov = fov
  end

  return self.cached_forward_x, self.cached_forward_y,
      -self.cached_forward_y, self.cached_forward_x,
      self.cached_half_fov_tangent
end

-- Creates shared perspective calculations independent from rendering surfaces.
function PerspectiveProjection.new(options)
  options = options or {}

  assert(options.viewpoint ~= nil,
    "perspective projection requires a viewpoint")
  assert(type(options.viewpoint.get_position) == "function",
    "perspective projection viewpoint must expose get_position")
  assert(type(options.viewpoint.get_rotation) == "function",
    "perspective projection viewpoint must expose get_rotation")

  local self = setmetatable({}, PerspectiveProjection)

  self.viewpoint = options.viewpoint
  self.horizon = options.horizon or 0.3
  self.near_distance = options.near_distance or 32
  self.far_distance = options.far_distance or 800
  self.horizontal_fov = options.horizontal_fov or math.rad(75)
  self.rotation_offset = options.rotation_offset or 0
  self.reference_distance = options.reference_distance or 32
  self.camera_elevation = options.camera_elevation or 32

  assert(type(self.reference_distance) == "number"
    and self.reference_distance > 0 and self.reference_distance < math.huge,
    "perspective projection reference distance must be finite and positive")
  assert(type(self.camera_elevation) == "number"
    and self.camera_elevation > -math.huge and self.camera_elevation < math.huge,
    "perspective projection camera elevation must be finite")
  assert(self.horizon >= 0 and self.horizon < 1,
    "perspective projection horizon must be between zero and one")
  assert(self.near_distance > 0,
    "perspective projection near_distance must be greater than zero")
  assert(self.far_distance > self.near_distance,
    "perspective projection far_distance must be greater than near_distance")
  assert(self.horizontal_fov > 0 and self.horizontal_fov < math.pi,
    "perspective projection horizontal_fov must be between zero and pi")

  return self
end

-- Returns the effective world-space viewing rotation.
function PerspectiveProjection:get_rotation()
  return self.viewpoint:get_rotation() + self.rotation_offset
end

-- Returns the current world-space viewpoint position.
function PerspectiveProjection:get_view_position()
  return self.viewpoint:get_position()
end

-- Returns the world-space angle from which projected points are visually observed.
function PerspectiveProjection:get_observation_angle(x, y)
  return self:get_rotation() + math.pi
end

-- Returns current perspective parameters for external presentation adapters.
function PerspectiveProjection:get_parameters()
  local view_x, view_y = self:get_view_position()

  return {
    view_position = { view_x, view_y },
    view_rotation = self.viewpoint:get_rotation(),
    rotation_offset = self.rotation_offset,
    horizon = self.horizon,
    near_distance = self.near_distance,
    far_distance = self.far_distance,
    horizontal_fov = self.horizontal_fov,
    camera_elevation = self.camera_elevation,
  }
end

-- Projects a world point with an optional absolute elevation.
function PerspectiveProjection:project_world_point(x, y, width, height, elevation)
  elevation = elevation or 0

  assert(type(x) == "number" and type(y) == "number",
    "projected world point coordinates must be numeric")
  assert(type(width) == "number" and width > 0,
    "projection output width must be greater than zero")
  assert(type(height) == "number" and height > 0,
    "projection output height must be greater than zero")
  assert(type(elevation) == "number"
    and elevation > -math.huge and elevation < math.huge,
    "projected world point elevation must be finite")

  local view_x, view_y = self:get_view_position()
  local forward_x, forward_y, right_x, right_y, half_fov_tangent =
      self:_get_projection_factors()

  local relative_x = x - view_x
  local relative_y = y - view_y
  local distance = relative_x * forward_x + relative_y * forward_y
  local lateral = relative_x * right_x + relative_y * right_y

  local result = {
    distance = distance,
    lateral = lateral,
    elevation = elevation,
    visible = false
  }

  if distance <= 0 then return result end

  local horizontal = lateral / (distance * half_fov_tangent)
  local vertical = (self.camera_elevation - elevation) / distance
  local u = 0.5 + horizontal * 0.5
  local v = self.horizon + vertical * (1 - self.horizon)

  result.x = u * width
  result.y = v * height
  result.u = u
  result.v = v
  result.scale = self.reference_distance / distance
  result.visible = distance >= self.near_distance
      and distance <= self.far_distance
      and u >= 0 and u <= 1
      and v >= 0 and v <= 1

  return result
end

-- Resolves a screen point onto a horizontal plane at the requested elevation.
function PerspectiveProjection:unproject_screen_point(x, y, width, height, elevation)
  elevation = elevation or 0

  assert(type(x) == "number" and type(y) == "number",
    "projected screen point coordinates must be numeric")
  assert(type(width) == "number" and width > 0,
    "projection output width must be greater than zero")
  assert(type(height) == "number" and height > 0,
    "projection output height must be greater than zero")
  assert(type(elevation) == "number"
    and elevation > -math.huge and elevation < math.huge,
    "projection plane elevation must be finite")

  local u = x / width
  local v = y / height

  local result = {
    u = u,
    v = v,
    elevation = elevation,
    visible = false
  }

  local relative_elevation = self.camera_elevation - elevation
  local normalized_y = (v - self.horizon) / (1 - self.horizon)

  -- The horizon and a plane through the camera have no unique finite intersection.
  if normalized_y == 0 or relative_elevation == 0 then return result end

  local distance = relative_elevation / normalized_y
  if distance <= 0 then return result end

  local forward_x, forward_y, right_x, right_y, half_fov_tangent =
      self:_get_projection_factors()

  local lateral = (u - 0.5) * 2 * distance * half_fov_tangent
  local view_x, view_y = self:get_view_position()

  result.x = view_x + forward_x * distance + right_x * lateral
  result.y = view_y + forward_y * distance + right_y * lateral
  result.distance = distance
  result.lateral = lateral
  result.scale = self.reference_distance / distance
  result.visible = distance >= self.near_distance
      and distance <= self.far_distance
      and u >= 0 and u <= 1
      and v >= 0 and v <= 1

  return result
end

-- Changes the normalized horizon position.
function PerspectiveProjection:set_horizon(horizon)
  assert(type(horizon) == "number" and horizon >= 0 and horizon < 1,
    "projected world plane horizon must be between zero and one")
  self.horizon = horizon
end

-- Changes the nearest visible depth without changing projection scale.
function PerspectiveProjection:set_near_distance(distance)
  assert(type(distance) == "number" and distance > 0, "projected world plane near_distance must be greater than zero")
  assert(distance < self.far_distance, "projected world plane near_distance must be less than far_distance")
  self.near_distance = distance
end

-- Changes the maximum visible world distance.
function PerspectiveProjection:set_far_distance(distance)
  assert(type(distance) == "number" and distance > self.near_distance,
    "projected world plane far_distance must be greater than near_distance")
  self.far_distance = distance
end

-- Changes the horizontal field of view in radians.
function PerspectiveProjection:set_horizontal_fov(fov)
  assert(type(fov) == "number" and fov > 0 and fov < math.pi,
    "projected world plane horizontal_fov must be between zero and pi")
  self.horizontal_fov = fov
end

-- Changes the orientation offset applied independently from the source camera.
function PerspectiveProjection:set_rotation_offset(rotation)
  assert(type(rotation) == "number", "projected world plane rotation offset must be numeric")
  self.rotation_offset = rotation
end

-- Changes camera elevation independently from clipping and billboard scale.
function PerspectiveProjection:set_camera_elevation(elevation)
  assert(type(elevation) == "number"
    and elevation > -math.huge and elevation < math.huge,
    "perspective projection camera elevation must be finite")

  self.camera_elevation = elevation
end

-- Changes the distance at which projected billboards have unit scale.
function PerspectiveProjection:set_reference_distance(distance)
  assert(type(distance) == "number" and distance > 0 and distance < math.huge,
    "perspective projection reference distance must be finite and positive")

  self.reference_distance = distance
end

return PerspectiveProjection
