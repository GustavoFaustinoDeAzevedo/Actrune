local love = require "love"
local ShaderCanvasPresenter = require("engine.render.shader_canvas_presenter")

local ProjectedWorldPlane = {}
ProjectedWorldPlane.__index = ProjectedWorldPlane

local shader_source = [[
extern vec2 camera_position;
extern number camera_rotation;
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

  float rotation = camera_rotation + rotation_offset;
  float screen_x = (texture_coords.x - 0.5) * 2.0;
  float lateral = screen_x * distance * tan(horizontal_fov * 0.5);

  vec2 forward = vec2(sin(rotation), -cos(rotation));
  vec2 right = vec2(cos(rotation), sin(rotation));
  vec2 world_position = camera_position + forward * distance + right * lateral;

  vec2 world_min = world_bounds.xy;
  vec2 world_size = world_bounds.zw - world_bounds.xy;
  vec2 source_uv = (world_position - world_min) / world_size;

  if (source_uv.x < 0.0 || source_uv.x > 1.0 || source_uv.y < 0.0 || source_uv.y > 1.0) return vec4(0.0);

  return Texel(texture, source_uv) * color;
}
]]

-- Creates a perspective presenter that samples a top-down world region as a navigable plane.
function ProjectedWorldPlane.new(options)
  options = options or {}

  assert(options.camera ~= nil, "projected world plane requires a camera")
  assert(options.source_region ~= nil, "projected world plane requires a source world region")

  local self = setmetatable({}, ProjectedWorldPlane)
  self.camera = options.camera
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

-- Returns the current projection values consumed by the shader.
function ProjectedWorldPlane:_get_uniforms()
  local camera_x, camera_y = self.camera:get_position()
  local min_x, min_y, max_x, max_y = self.source_region:get_bounds()

  return {
    camera_position = { camera_x, camera_y },
    camera_rotation = self.camera.rotation,
    rotation_offset = self.rotation_offset,
    horizon = self.horizon,
    near_distance = self.near_distance,
    far_distance = self.far_distance,
    horizontal_fov = self.horizontal_fov,
    world_bounds = { min_x, min_y, max_x, max_y }
  }
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
