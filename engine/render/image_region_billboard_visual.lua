local love = require "love"

local ImageRegionBillboardVisual = {}
ImageRegionBillboardVisual.__index = ImageRegionBillboardVisual

-- Creates a billboard visual backed by one rectangular image region.
function ImageRegionBillboardVisual.new(options)
  options = options or {}

  assert(options.region ~= nil, "image region billboard visual requires a region")
  assert(type(options.region.get_image) == "function", "image region must expose get_image")
  assert(type(options.region.get_quad) == "function", "image region must expose get_quad")
  assert(type(options.region.get_dimensions) == "function", "image region must expose get_dimensions")

  local source_width, source_height = options.region:get_dimensions()

  local self = setmetatable({}, ImageRegionBillboardVisual)
  self.region = options.region
  self.width = options.width or source_width
  self.height = options.height or source_height
  self.anchor_x = options.anchor_x or 0.5
  self.anchor_y = options.anchor_y or 1

  assert(type(self.width) == "number" and self.width > 0, "image region billboard width must be greater than zero")
  assert(type(self.height) == "number" and self.height > 0, "image region billboard height must be greater than zero")

  return self
end

-- Changes the displayed local dimensions without modifying the source region.
function ImageRegionBillboardVisual:set_size(width, height)
  assert(type(width) == "number" and width > 0, "image region billboard width must be greater than zero")
  assert(type(height) == "number" and height > 0, "image region billboard height must be greater than zero")

  self.width = width
  self.height = height
end

-- Changes the normalized point anchored to the projected world position.
function ImageRegionBillboardVisual:set_anchor(anchor_x, anchor_y)
  assert(type(anchor_x) == "number" and type(anchor_y) == "number", "image region billboard anchor must be numeric")
  self.anchor_x = anchor_x
  self.anchor_y = anchor_y
end

-- Draws the configured image region at its local visual dimensions.
function ImageRegionBillboardVisual:draw(context)
  local image = self.region:get_image()
  local quad = self.region:get_quad()
  local source_width, source_height = self.region:get_dimensions()

  love.graphics.push("all")
  love.graphics.setColor(1, 1, 1, 1)

  love.graphics.draw(
    image,
    quad,
    0,
    0,
    0,
    self.width / source_width,
    self.height / source_height,
    source_width * self.anchor_x,
    source_height * self.anchor_y
  )

  love.graphics.pop()
end

return ImageRegionBillboardVisual
