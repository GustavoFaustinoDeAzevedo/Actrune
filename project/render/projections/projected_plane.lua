local love = require "love"
local ShaderCanvasPresenter = require("engine.render.shader_canvas_presenter")

local ProjectedPlane = {}
ProjectedPlane.__index = ProjectedPlane

local shader_source = [[
extern number horizon;
extern number vanishing_x;
extern number near_scale;
extern number far_scale;
extern number depth_curve;
extern vec2 source_offset;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
  float safe_horizon = clamp(horizon, 0.0, 0.9999);

  if (texture_coords.y <= safe_horizon) return vec4(0.0);

  float normalized_y = (texture_coords.y - safe_horizon) / (1.0 - safe_horizon);
  float depth = pow(normalized_y, max(depth_curve, 0.0001));
  float row_scale = mix(far_scale, near_scale, depth);

  if (abs(row_scale) < 0.0001) return vec4(0.0);

  vec2 source_uv;
  source_uv.x = vanishing_x + (texture_coords.x - vanishing_x) / row_scale + source_offset.x;
  source_uv.y = depth + source_offset.y;

  if (source_uv.x < 0.0 || source_uv.x > 1.0 || source_uv.y < 0.0 || source_uv.y > 1.0) return vec4(0.0);

  return Texel(texture, source_uv) * color;
}
]]

-- Creates a configurable projected-plane canvas presenter.
function ProjectedPlane.new(options)
  options = options or {}

  local self = setmetatable({}, ProjectedPlane)
  self.enabled = options.enabled ~= false
  self.horizon = options.horizon or 0.2
  self.vanishing_x = options.vanishing_x or 0.5
  self.near_scale = options.near_scale or 1
  self.far_scale = options.far_scale or 0.15
  self.depth_curve = options.depth_curve or 1.5
  self.offset_x = options.offset_x or 0
  self.offset_y = options.offset_y or 0

  assert(self.horizon >= 0 and self.horizon < 1, "projected plane horizon must be between zero and one")
  assert(self.vanishing_x >= 0 and self.vanishing_x <= 1, "projected plane vanishing_x must be between zero and one")
  assert(self.near_scale > 0, "projected plane near_scale must be greater than zero")
  assert(self.far_scale > 0, "projected plane far_scale must be greater than zero")
  assert(self.depth_curve > 0, "projected plane depth_curve must be greater than zero")

  self.presenter = ShaderCanvasPresenter.new({
    shader = shader_source,
    uniform_provider = function()
      return self:_get_uniforms()
    end
  })

  return self
end

-- Returns the current shader uniforms describing the plane projection.
function ProjectedPlane:_get_uniforms()
  return {
    horizon = self.horizon,
    vanishing_x = self.vanishing_x,
    near_scale = self.near_scale,
    far_scale = self.far_scale,
    depth_curve = self.depth_curve,
    source_offset = { self.offset_x, self.offset_y }
  }
end

-- Enables or disables projected presentation without replacing the presenter.
function ProjectedPlane:set_enabled(enabled)
  self.enabled = enabled == true
end

-- Changes the normalized vertical horizon position.
function ProjectedPlane:set_horizon(horizon)
  assert(type(horizon) == "number" and horizon >= 0 and horizon < 1,
    "projected plane horizon must be between zero and one")
  self.horizon = horizon
end

-- Changes the normalized horizontal vanishing point.
function ProjectedPlane:set_vanishing_x(vanishing_x)
  assert(type(vanishing_x) == "number" and vanishing_x >= 0 and vanishing_x <= 1,
    "projected plane vanishing_x must be between zero and one")
  self.vanishing_x = vanishing_x
end

-- Changes the horizontal scale at the near edge of the projection.
function ProjectedPlane:set_near_scale(scale)
  assert(type(scale) == "number" and scale > 0, "projected plane near scale must be greater than zero")
  self.near_scale = scale
end

-- Changes the horizontal scale at the horizon side of the projection.
function ProjectedPlane:set_far_scale(scale)
  assert(type(scale) == "number" and scale > 0, "projected plane far scale must be greater than zero")
  self.far_scale = scale
end

-- Changes how depth is distributed between the horizon and the near edge.
function ProjectedPlane:set_depth_curve(curve)
  assert(type(curve) == "number" and curve > 0, "projected plane depth curve must be greater than zero")
  self.depth_curve = curve
end

-- Changes the source texture offset sampled by the projection.
function ProjectedPlane:set_offset(x, y)
  self.offset_x = x
  self.offset_y = y
end

-- Presents the canvas normally or through the configured projected-plane shader.
function ProjectedPlane:present(canvas, context)
  if self.enabled then
    self.presenter:present(canvas, context)
    return
  end

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(canvas, 0, 0)
end

return ProjectedPlane
