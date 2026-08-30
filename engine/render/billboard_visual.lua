local love = require "love"

local BillboardVisual = {}
BillboardVisual.__index = BillboardVisual

-- Creates a billboard visual with configurable local size and normalized anchor.
function BillboardVisual.new(options)
  options = options or {}

  local self = setmetatable({}, BillboardVisual)
  self.width = options.width or 1
  self.height = options.height or 1
  self.anchor_x = options.anchor_x or 0.5
  self.anchor_y = options.anchor_y or 1
  self.draw_callback = options.draw

  assert(type(self.width) == "number" and self.width > 0, "billboard visual width must be greater than zero")
  assert(type(self.height) == "number" and self.height > 0, "billboard visual height must be greater than zero")
  assert(type(self.anchor_x) == "number", "billboard visual anchor_x must be numeric")
  assert(type(self.anchor_y) == "number", "billboard visual anchor_y must be numeric")
  assert(type(self.draw_callback) == "function", "billboard visual requires a draw callback")

  return self
end

-- Changes the local dimensions of the billboard visual.
function BillboardVisual:set_size(width, height)
  assert(type(width) == "number" and width > 0, "billboard visual width must be greater than zero")
  assert(type(height) == "number" and height > 0, "billboard visual height must be greater than zero")

  self.width = width
  self.height = height
end

-- Changes the normalized anchor positioned at the projected world point.
function BillboardVisual:set_anchor(anchor_x, anchor_y)
  assert(type(anchor_x) == "number" and type(anchor_y) == "number", "billboard visual anchor must be numeric")

  self.anchor_x = anchor_x
  self.anchor_y = anchor_y
end

-- Draws the visual relative to its configured anchor.
function BillboardVisual:draw(context)
  love.graphics.push("all")
  love.graphics.translate(-self.width * self.anchor_x, -self.height * self.anchor_y)
  self.draw_callback(self.width, self.height, context)
  love.graphics.pop()
end

return BillboardVisual
