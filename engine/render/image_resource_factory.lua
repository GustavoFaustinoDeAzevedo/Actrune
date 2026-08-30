local love = require "love"

local ImageResourceFactory = {}

-- Creates one runtime LÖVE image from a serializable image resource definition.
function ImageResourceFactory.create(definition)
  assert(type(definition) == "table", "image resource definition must be a table")
  assert(type(definition.path) == "string" and definition.path ~= "", "image resource requires a non-empty path")

  return love.graphics.newImage(definition.path)
end

return ImageResourceFactory
