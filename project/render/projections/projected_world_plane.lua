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
extern number camera_elevation;
extern number plane_elevation;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
  float relative_elevation = camera_elevation - plane_elevation;
  float normalized_y = (texture_coords.y - horizon) / (1.0 - horizon);

  if (normalized_y == 0.0 || relative_elevation == 0.0) return vec4(0.0);

  float distance = relative_elevation / normalized_y;
  if (distance < near_distance || distance > far_distance) return vec4(0.0);

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

-- Creates a plane presenter using an injected projection and source region.
function ProjectedWorldPlane.new(options)
  options = options or {}

  assert(options.projection ~= nil
    and type(options.projection.get_parameters) == "function",
    "projected world plane requires a projection exposing get_parameters")
  assert(options.source_region ~= nil
    and type(options.source_region.get_bounds) == "function",
    "projected world plane requires a source region exposing get_bounds")

  local elevation = options.elevation or 0

  assert(type(elevation) == "number"
    and elevation > -math.huge and elevation < math.huge,
    "projected world plane elevation must be finite")
  assert(options.elevation_provider == nil
    or type(options.elevation_provider) == "function",
    "projected world plane elevation provider must be a function")

  local self = setmetatable({
    projection = options.projection,
    source_region = options.source_region,
    enabled = options.enabled ~= false,
    elevation = elevation,
    elevation_provider = options.elevation_provider,
  }, ProjectedWorldPlane)

  self.presenter = ShaderCanvasPresenter.new({
    shader = shader_source,
    uniform_provider = function()
      return self:_get_uniforms()
    end
  })

  return self
end

-- Returns this plane's absolute elevation independently from the shared projection.
function ProjectedWorldPlane:get_elevation()
  local elevation = self.elevation

  if self.elevation_provider ~= nil then
    elevation = self.elevation_provider()
  end

  assert(type(elevation) == "number"
    and elevation > -math.huge and elevation < math.huge,
    "projected world plane elevation must be finite")

  return elevation
end

-- Combines shared perspective parameters with this plane's texture bounds.
function ProjectedWorldPlane:_get_uniforms()
  local parameters = self.projection:get_parameters()
  local min_x, min_y, max_x, max_y = self.source_region:get_bounds()

  parameters.world_bounds = { min_x, min_y, max_x, max_y }
  parameters.plane_elevation = self:get_elevation()

  return parameters
end

-- Enables or disables perspective presentation of this plane.
function ProjectedWorldPlane:set_enabled(enabled)
  self.enabled = enabled == true
end

-- Presents the captured region through perspective or directly.
function ProjectedWorldPlane:present(canvas, context)
  if self.enabled then
    self.presenter:present(canvas, context)
    return
  end

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(canvas, 0, 0)
end

return ProjectedWorldPlane
