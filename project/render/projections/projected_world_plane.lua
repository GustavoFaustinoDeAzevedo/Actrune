local love = require "love"
local ShaderCanvasPresenter = require("engine.render.shader_canvas_presenter")

local ProjectedWorldPlane = {}
ProjectedWorldPlane.__index = ProjectedWorldPlane

local shader_source = [[
extern vec2 view_position;
extern number view_rotation;
extern number rotation_offset;
extern number horizon;
extern number near_distance;
extern number far_distance;
extern number horizontal_fov;
extern vec4 world_bounds;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
  if (texture_coords.y <= horizon) return vec4(0.0);

  float normalized_y = (texture_coords.y - horizon) / (1.0 - horizon);
  if (normalized_y <= 0.0001) return vec4(0.0);

  float distance = near_distance / normalized_y;
  if (distance > far_distance) return vec4(0.0);

  float rotation = view_rotation + rotation_offset;
  float screen_x = (texture_coords.x - 0.5) * 2.0;
  float lateral = screen_x * distance * tan(horizontal_fov * 0.5);

  vec2 forward = vec2(cos(rotation), sin(rotation));
  vec2 right = vec2(-sin(rotation), cos(rotation));
  vec2 world_position = view_position + forward * distance + right * lateral;

  vec2 world_min = world_bounds.xy;
  vec2 world_size = world_bounds.zw - world_bounds.xy;
  vec2 source_uv = (world_position - world_min) / world_size;

  if (source_uv.x < 0.0 || source_uv.x > 1.0 || source_uv.y < 0.0 || source_uv.y > 1.0) return vec4(0.0);

  return Texel(texture, source_uv) * color;
}
]]

-- Resolves forward and right vectors using the Actrune world rotation convention.
local function resolve_basis(rotation)
  local forward_x = math.cos(rotation)
  local forward_y = math.sin(rotation)
  local right_x = -forward_y
  local right_y = forward_x

  return forward_x, forward_y, right_x, right_y
end

-- Creates a perspective presenter that samples a top-down world region as a navigable plane.
function ProjectedWorldPlane.new(options)
  options = options or {}

  assert(options.viewpoint ~= nil, "projected world plane requires a viewpoint")
  assert(type(options.viewpoint.get_position) == "function", "projected world plane viewpoint must expose get_position")
  assert(type(options.viewpoint.get_rotation) == "function", "projected world plane viewpoint must expose get_rotation")
  assert(options.source_region ~= nil, "projected world plane requires a source world region")

  local self = setmetatable({}, ProjectedWorldPlane)
  self.viewpoint = options.viewpoint
  self.source_region = options.source_region
  self.enabled = options.enabled ~= false
  self.horizon = options.horizon or 0.3
  self.near_distance = options.near_distance or 32
  self.far_distance = options.far_distance or 800
  self.horizontal_fov = options.horizontal_fov or math.rad(75)
  self.rotation_offset = options.rotation_offset or 0

  assert(self.horizon >= 0 and self.horizon < 1, "projected world plane horizon must be between zero and one")
  assert(self.near_distance > 0, "projected world plane near_distance must be greater than zero")
  assert(self.far_distance > self.near_distance, "projected world plane far_distance must be greater than near_distance")
  assert(self.horizontal_fov > 0 and self.horizontal_fov < math.pi,
    "projected world plane horizontal_fov must be between zero and pi")

  self.presenter = ShaderCanvasPresenter.new({
    shader = shader_source,
    uniform_provider = function()
      return self:_get_uniforms()
    end
  })

  return self
end

-- Returns the effective world-space viewing rotation.
function ProjectedWorldPlane:get_rotation()
  return self.viewpoint:get_rotation() + self.rotation_offset
end

-- Returns the current world-space viewpoint position.
function ProjectedWorldPlane:get_view_position()
  return self.viewpoint:get_position()
end

-- Returns the world-space angle from which projected points are visually observed.
function ProjectedWorldPlane:get_observation_angle(x, y)
  return self:get_rotation() + math.pi
end

-- Returns the current projection values consumed by the shader.
function ProjectedWorldPlane:_get_uniforms()
  local view_x, view_y = self.viewpoint:get_position()
  local min_x, min_y, max_x, max_y = self.source_region:get_bounds()

  return {
    view_position = { view_x, view_y },
    view_rotation = self.viewpoint:get_rotation(),
    rotation_offset = self.rotation_offset,
    horizon = self.horizon,
    near_distance = self.near_distance,
    far_distance = self.far_distance,
    horizontal_fov = self.horizontal_fov,
    world_bounds = { min_x, min_y, max_x, max_y }
  }
end

-- Projects one world-space point into the projected output surface.
function ProjectedWorldPlane:project_world_point(x, y, width, height)
  assert(type(x) == "number" and type(y) == "number", "projected world point coordinates must be numeric")
  assert(type(width) == "number" and width > 0, "projection output width must be greater than zero")
  assert(type(height) == "number" and height > 0, "projection output height must be greater than zero")

  local view_x, view_y = self.viewpoint:get_position()
  local forward_x, forward_y, right_x, right_y = resolve_basis(self:get_rotation())
  local relative_x = x - view_x
  local relative_y = y - view_y
  local distance = relative_x * forward_x + relative_y * forward_y
  local lateral = relative_x * right_x + relative_y * right_y

  local result = {
    distance = distance,
    lateral = lateral,
    visible = false
  }

  if distance <= 0 then return result end

  local scale = self.near_distance / distance
  local horizontal = lateral / (distance * math.tan(self.horizontal_fov * 0.5))
  local u = 0.5 + horizontal * 0.5
  local v = self.horizon + scale * (1 - self.horizon)

  result.x = u * width
  result.y = v * height
  result.u = u
  result.v = v
  result.scale = scale
  result.visible = distance >= self.near_distance
      and distance <= self.far_distance
      and u >= 0 and u <= 1
      and v >= self.horizon and v <= 1

  return result
end

-- Resolves one output-space point back onto the projected world plane.
function ProjectedWorldPlane:unproject_screen_point(x, y, width, height)
  assert(type(x) == "number" and type(y) == "number", "projected screen point coordinates must be numeric")
  assert(type(width) == "number" and width > 0, "projection output width must be greater than zero")
  assert(type(height) == "number" and height > 0, "projection output height must be greater than zero")

  local u = x / width
  local v = y / height

  local result = {
    u = u,
    v = v,
    visible = false
  }

  if v <= self.horizon then return result end

  local normalized_y = (v - self.horizon) / (1 - self.horizon)
  if normalized_y <= 0 then return result end

  local distance = self.near_distance / normalized_y
  local horizontal = (u - 0.5) * 2
  local lateral = horizontal * distance * math.tan(self.horizontal_fov * 0.5)

  local view_x, view_y = self.viewpoint:get_position()
  local forward_x, forward_y, right_x, right_y = resolve_basis(self:get_rotation())

  result.x = view_x + forward_x * distance + right_x * lateral
  result.y = view_y + forward_y * distance + right_y * lateral
  result.distance = distance
  result.lateral = lateral
  result.scale = normalized_y
  result.visible = distance >= self.near_distance
      and distance <= self.far_distance
      and u >= 0 and u <= 1
      and v <= 1

  return result
end

-- Enables or disables perspective presentation.
function ProjectedWorldPlane:set_enabled(enabled)
  self.enabled = enabled == true
end

-- Changes the normalized horizon position.
function ProjectedWorldPlane:set_horizon(horizon)
  assert(type(horizon) == "number" and horizon >= 0 and horizon < 1,
    "projected world plane horizon must be between zero and one")
  self.horizon = horizon
end

-- Changes the world distance represented at the bottom edge of the projection.
function ProjectedWorldPlane:set_near_distance(distance)
  assert(type(distance) == "number" and distance > 0, "projected world plane near_distance must be greater than zero")
  assert(distance < self.far_distance, "projected world plane near_distance must be less than far_distance")
  self.near_distance = distance
end

-- Changes the maximum visible world distance.
function ProjectedWorldPlane:set_far_distance(distance)
  assert(type(distance) == "number" and distance > self.near_distance,
    "projected world plane far_distance must be greater than near_distance")
  self.far_distance = distance
end

-- Changes the horizontal field of view in radians.
function ProjectedWorldPlane:set_horizontal_fov(fov)
  assert(type(fov) == "number" and fov > 0 and fov < math.pi,
    "projected world plane horizontal_fov must be between zero and pi")
  self.horizontal_fov = fov
end

-- Changes the orientation offset applied independently from the source camera.
function ProjectedWorldPlane:set_rotation_offset(rotation)
  assert(type(rotation) == "number", "projected world plane rotation offset must be numeric")
  self.rotation_offset = rotation
end

-- Presents the source canvas normally or as a perspective world plane.
function ProjectedWorldPlane:present(canvas, context)
  if self.enabled then
    self.presenter:present(canvas, context)
    return
  end

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(canvas, 0, 0)
end

return ProjectedWorldPlane
