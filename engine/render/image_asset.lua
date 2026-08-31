local love = require "love"

local ImageAsset = {}
ImageAsset.__index = ImageAsset

-- Creates a drawable asset around one LÖVE image.
function ImageAsset.new(image)
  assert(image ~= nil, "image asset requires an image")
  return setmetatable({ image = image }, ImageAsset)
end

-- Returns the underlying LÖVE image when lower-level image access is required.
function ImageAsset:get_image()
  return self.image
end

-- Returns the complete source image dimensions.
function ImageAsset:get_dimensions()
  return self.image:getDimensions()
end

-- Draws the complete image using an arbitrary local transformation.
function ImageAsset:draw(x, y, rotation, scale_x, scale_y, origin_x, origin_y)
  love.graphics.draw(
    self.image,
    x or 0,
    y or 0,
    rotation or 0,
    scale_x or 1,
    scale_y or 1,
    origin_x or 0,
    origin_y or 0
  )
end

return ImageAsset
