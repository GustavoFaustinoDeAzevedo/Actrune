local OrthographicProjection = {}
OrthographicProjection.__index = OrthographicProjection

-- Creates a camera-backed projection with screen-vertical elevation displacement.
function OrthographicProjection.new(options)
  options = options or {}

  local camera = options.camera
  local elevation_scale = options.elevation_scale or 1

  assert(camera ~= nil and type(camera.world_to_screen) == "function",
    "orthographic projection requires a camera exposing world_to_screen")
  assert(type(camera.get_zoom) == "function",
    "orthographic projection camera must expose get_zoom")
  assert(type(camera.get_rotation) == "function",
    "orthographic projection camera must expose get_rotation")
  assert(type(camera.get_viewport) == "function",
    "orthographic projection camera must expose get_viewport")
  assert(type(elevation_scale) == "number"
    and elevation_scale >= 0 and elevation_scale < math.huge,
    "orthographic projection elevation scale must be finite and non-negative")

  return setmetatable({
    camera = camera,
    elevation_scale = elevation_scale
  }, OrthographicProjection)
end

-- Returns the direction toward the bottom of the camera view for sprite selection.
function OrthographicProjection:get_observation_angle(x, y)
  return self.camera:get_rotation() + math.pi * 0.5
end

-- Projects an elevated world point without perspective scaling.
function OrthographicProjection:project_world_point(x, y, width, height, elevation)
  elevation = elevation or 0

  assert(type(x) == "number" and type(y) == "number",
    "orthographic world point coordinates must be numeric")
  assert(type(width) == "number" and width > 0,
    "orthographic output width must be greater than zero")
  assert(type(height) == "number" and height > 0,
    "orthographic output height must be greater than zero")
  assert(type(elevation) == "number"
    and elevation > -math.huge and elevation < math.huge,
    "orthographic world point elevation must be finite")

  local screen_x, screen_y = self.camera:world_to_screen(x, y)
  local zoom = self.camera:get_zoom()
  local _, viewport_y, _, viewport_height = self.camera:get_viewport()

  -- Signed view depth draws upper ground positions before lower ones.
  local distance = -(screen_y - viewport_y - viewport_height * 0.5) / zoom

  return {
    x = screen_x,
    y = screen_y - elevation * self.elevation_scale * zoom,
    distance = distance,
    elevation = elevation,
    scale = zoom,
    visible = true
  }
end

return OrthographicProjection
