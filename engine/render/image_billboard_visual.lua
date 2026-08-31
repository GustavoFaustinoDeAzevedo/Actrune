local love = require "love"

local ImageBillboardVisual = {}
ImageBillboardVisual.__index = ImageBillboardVisual

-- Creates a billboard visual backed by any drawable image source.
function ImageBillboardVisual.new(options)
  options = options or {}

  assert(options.source ~= nil, "image billboard visual requires a source")
  assert(type(options.source.get_dimensions) == "function", "image billboard source must expose get_dimensions")
  assert(type(options.source.draw) == "function", "image billboard source must expose draw")

  local source_width, source_height = options.source:get_dimensions()

  local self = setmetatable({}, ImageBillboardVisual)
  self.source = options.source
  self.width = options.width or source_width
  self.height = options.height or source_height
  self.anchor_x = options.anchor_x or 0.5
  self.anchor_y = options.anchor_y or 1
  self.flip_x = options.flip_x == true
  self.flip_y = options.flip_y == true

  assert(type(self.width) == "number" and self.width > 0, "image billboard width must be greater than zero")
  assert(type(self.height) == "number" and self.height > 0, "image billboard height must be greater than zero")
  assert(type(self.anchor_x) == "number" and type(self.anchor_y) == "number", "image billboard anchor must be numeric")

  return self
end

-- Changes the displayed local dimensions without modifying the source asset.
function ImageBillboardVisual:set_size(width, height)
  assert(type(width) == "number" and width > 0, "image billboard width must be greater than zero")
  assert(type(height) == "number" and height > 0, "image billboard height must be greater than zero")
  self.width = width
  self.height = height
end

-- Changes the normalized point anchored to the projected world position.
function ImageBillboardVisual:set_anchor(anchor_x, anchor_y)
  assert(type(anchor_x) == "number" and type(anchor_y) == "number", "image billboard anchor must be numeric")
  self.anchor_x = anchor_x
  self.anchor_y = anchor_y
end

-- Changes optional horizontal and vertical source mirroring.
function ImageBillboardVisual:set_flip(flip_x, flip_y)
  self.flip_x = flip_x == true
  self.flip_y = flip_y == true
end

-- Draws the image source using the configured billboard dimensions and anchor.
function ImageBillboardVisual:draw(context)
  local source_width, source_height = self.source:get_dimensions()
  local scale_x = self.width / source_width
  local scale_y = self.height / source_height

  if self.flip_x then scale_x = -scale_x end
  if self.flip_y then scale_y = -scale_y end

  love.graphics.push("all")
  love.graphics.setColor(1, 1, 1, 1)

  self.source:draw(
    0,
    0,
    0,
    scale_x,
    scale_y,
    source_width * self.anchor_x,
    source_height * self.anchor_y
  )

  love.graphics.pop()
end

return ImageBillboardVisual
