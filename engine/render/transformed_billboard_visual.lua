local love = require "love"

local TransformedBillboardVisual = {}
TransformedBillboardVisual.__index = TransformedBillboardVisual

-- Creates a drawable wrapper that applies a local transformation to another billboard visual.
function TransformedBillboardVisual.new(options)
  options = options or {}

  assert(options.visual ~= nil and type(options.visual.draw) == "function",
    "transformed billboard visual requires a drawable visual")

  local self = setmetatable({}, TransformedBillboardVisual)
  self.visual = options.visual
  self.x = options.x or 0
  self.y = options.y or 0
  self.rotation = options.rotation or 0
  self.scale_x = options.scale_x or 1
  self.scale_y = options.scale_y or 1

  assert(type(self.x) == "number" and type(self.y) == "number",
    "transformed billboard visual position must be numeric")
  assert(type(self.rotation) == "number",
    "transformed billboard visual rotation must be numeric")
  assert(type(self.scale_x) == "number" and self.scale_x ~= 0,
    "transformed billboard visual scale_x must be non-zero")
  assert(type(self.scale_y) == "number" and self.scale_y ~= 0,
    "transformed billboard visual scale_y must be non-zero")

  return self
end

-- Changes the local translation applied before drawing the wrapped visual.
function TransformedBillboardVisual:set_position(x, y)
  assert(type(x) == "number" and type(y) == "number",
    "transformed billboard visual position must be numeric")

  self.x = x
  self.y = y
end

-- Changes the local rotation applied to the wrapped visual.
function TransformedBillboardVisual:set_rotation(rotation)
  assert(type(rotation) == "number",
    "transformed billboard visual rotation must be numeric")

  self.rotation = rotation
end

-- Changes the local scale applied independently on each axis.
function TransformedBillboardVisual:set_scale(scale_x, scale_y)
  scale_y = scale_y or scale_x

  assert(type(scale_x) == "number" and scale_x ~= 0,
    "transformed billboard visual scale_x must be non-zero")
  assert(type(scale_y) == "number" and scale_y ~= 0,
    "transformed billboard visual scale_y must be non-zero")

  self.scale_x = scale_x
  self.scale_y = scale_y
end

-- Draws the wrapped billboard visual through the configured local transformation.
function TransformedBillboardVisual:draw(context)
  love.graphics.push("all")
  love.graphics.translate(self.x, self.y)
  love.graphics.rotate(self.rotation)
  love.graphics.scale(self.scale_x, self.scale_y)

  self.visual:draw(context)

  love.graphics.pop()
end

-- Updates the wrapped visual when it exposes time-dependent behavior.
function TransformedBillboardVisual:update(dt, context)
  if type(self.visual.update) == "function" then self.visual:update(dt, context) end
end

return TransformedBillboardVisual
