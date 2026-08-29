local love = require "love"

local LayerTransform2D = {}
LayerTransform2D.__index = LayerTransform2D

-- Creates a configurable affine transformation applied to one render layer.
function LayerTransform2D.new(options)
  options = options or {}

  local self = setmetatable({}, LayerTransform2D)
  self.x = options.x or 0
  self.y = options.y or 0
  self.rotation = options.rotation or 0
  self.scale_x = options.scale_x or 1
  self.scale_y = options.scale_y or 1
  self.shear_x = options.shear_x or 0
  self.shear_y = options.shear_y or 0
  self.pivot_x = options.pivot_x or 0
  self.pivot_y = options.pivot_y or 0

  return self
end

-- Changes the translation applied to the layer.
function LayerTransform2D:set_position(x, y)
  self.x = x
  self.y = y
end

-- Changes the rotation applied around the configured pivot.
function LayerTransform2D:set_rotation(rotation)
  self.rotation = rotation
end

-- Changes the layer scale independently on each axis.
function LayerTransform2D:set_scale(scale_x, scale_y)
  self.scale_x = scale_x
  self.scale_y = scale_y or scale_x
end

-- Changes the layer shear independently on each axis.
function LayerTransform2D:set_shear(shear_x, shear_y)
  self.shear_x = shear_x
  self.shear_y = shear_y or 0
end

-- Changes the world-space pivot used by rotation, scale, and shear.
function LayerTransform2D:set_pivot(x, y)
  self.pivot_x = x
  self.pivot_y = y
end

-- Applies the layer transformation to subsequent drawing.
function LayerTransform2D:begin()
  love.graphics.push()

  love.graphics.translate(self.x, self.y)
  love.graphics.translate(self.pivot_x, self.pivot_y)
  love.graphics.rotate(self.rotation)
  love.graphics.shear(self.shear_x, self.shear_y)
  love.graphics.scale(self.scale_x, self.scale_y)
  love.graphics.translate(-self.pivot_x, -self.pivot_y)
end

-- Restores the graphics transformation that existed before this layer transform.
function LayerTransform2D:finish()
  love.graphics.pop()
end

return LayerTransform2D
