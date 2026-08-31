local love = require "love"
local ImageAsset = require("engine.render.image_asset")

local ImageResourceFactory = {}

-- Creates one drawable image asset from a serializable resource definition.
function ImageResourceFactory.create(definition)
  assert(type(definition) == "table", "image resource definition must be a table")
  assert(type(definition.path) == "string" and definition.path ~= "", "image resource requires a non-empty path")

  return ImageAsset.new(love.graphics.newImage(definition.path))
end

return ImageResourceFactory
