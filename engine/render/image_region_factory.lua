local love = require "love"
local ImageRegion = require("engine.render.image_region")

local ImageRegionFactory = {}

-- Creates one image region from serialized data and a referenced image resource.
function ImageRegionFactory.create(definition, context)
  assert(type(definition) == "table", "image region definition must be a table")
  assert(context ~= nil and type(context.resolve_resource) == "function",
    "image region factory requires resource resolution")

  local image = context.resolve_resource("image", definition.image)
  local image_width, image_height = image:getDimensions()

  local x = definition.x or 0
  local y = definition.y or 0
  local width = definition.width
  local height = definition.height

  assert(type(width) == "number" and width > 0, "image region width must be greater than zero")
  assert(type(height) == "number" and height > 0, "image region height must be greater than zero")
  assert(x >= 0 and y >= 0, "image region position must not be negative")
  assert(x + width <= image_width, "image region exceeds source image width")
  assert(y + height <= image_height, "image region exceeds source image height")

  local quad = love.graphics.newQuad(x, y, width, height, image_width, image_height)

  return ImageRegion.new(image, quad, x, y, width, height)
end

return ImageRegionFactory
