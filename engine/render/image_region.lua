local ImageRegion = {}
ImageRegion.__index = ImageRegion

-- Creates a rectangular region over one image using a prebuilt LÖVE quad.
function ImageRegion.new(image, quad, x, y, width, height)
  assert(image ~= nil, "image region requires an image")
  assert(quad ~= nil, "image region requires a quad")
  assert(type(x) == "number" and type(y) == "number", "image region position must be numeric")
  assert(type(width) == "number" and width > 0, "image region width must be greater than zero")
  assert(type(height) == "number" and height > 0, "image region height must be greater than zero")

  return setmetatable({
    image = image,
    quad = quad,
    x = x,
    y = y,
    width = width,
    height = height
  }, ImageRegion)
end

-- Returns the source image used by this region.
function ImageRegion:get_image()
  return self.image
end

-- Returns the LÖVE quad describing this image region.
function ImageRegion:get_quad()
  return self.quad
end

-- Returns the source-space region dimensions.
function ImageRegion:get_dimensions()
  return self.width, self.height
end

-- Returns the source-space rectangle covered by this region.
function ImageRegion:get_bounds()
  return self.x, self.y, self.width, self.height
end

return ImageRegion
