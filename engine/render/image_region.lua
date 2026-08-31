local love = require "love"

local ImageRegion = {}
ImageRegion.__index = ImageRegion

-- Creates a rectangular drawable region over one image asset.
function ImageRegion.new(image_asset, quad, x, y, width, height)
  assert(image_asset ~= nil and type(image_asset.get_image) == "function", "image region requires an image asset")
  assert(quad ~= nil, "image region requires a quad")
  assert(type(x) == "number" and type(y) == "number", "image region position must be numeric")
  assert(type(width) == "number" and width > 0, "image region width must be greater than zero")
  assert(type(height) == "number" and height > 0, "image region height must be greater than zero")

  return setmetatable({
    image_asset = image_asset,
    quad = quad,
    x = x,
    y = y,
    width = width,
    height = height
  }, ImageRegion)
end

-- Returns the source image asset used by this region.
function ImageRegion:get_image_asset()
  return self.image_asset
end

-- Returns the LÖVE quad describing this image region.
function ImageRegion:get_quad()
  return self.quad
end

-- Returns the region dimensions in source-image pixels.
function ImageRegion:get_dimensions()
  return self.width, self.height
end

-- Returns the source-space rectangle covered by this region.
function ImageRegion:get_bounds()
  return self.x, self.y, self.width, self.height
end

-- Draws this image region using an arbitrary local transformation.
function ImageRegion:draw(x, y, rotation, scale_x, scale_y, origin_x, origin_y)
  love.graphics.draw(
    self.image_asset:get_image(),
    self.quad,
    x or 0,
    y or 0,
    rotation or 0,
    scale_x or 1,
    scale_y or 1,
    origin_x or 0,
    origin_y or 0
  )
end

return ImageRegion
