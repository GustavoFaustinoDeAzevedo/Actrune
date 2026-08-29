local love = require "love"

local WorldRegionView = {}
WorldRegionView.__index = WorldRegionView

-- Creates a view that maps a rectangular world region onto the current render target.
function WorldRegionView.new(options)
  options = options or {}

  local self = setmetatable({}, WorldRegionView)
  self:set_bounds(options.min_x or 0, options.min_y or 0, options.max_x or 1, options.max_y or 1)
  return self
end

-- Changes the world-space region mapped onto the current render target.
function WorldRegionView:set_bounds(min_x, min_y, max_x, max_y)
  assert(type(min_x) == "number" and type(min_y) == "number", "world region minimum coordinates must be numeric")
  assert(type(max_x) == "number" and type(max_y) == "number", "world region maximum coordinates must be numeric")
  assert(max_x > min_x, "world region max_x must be greater than min_x")
  assert(max_y > min_y, "world region max_y must be greater than min_y")

  self.min_x = min_x
  self.min_y = min_y
  self.max_x = max_x
  self.max_y = max_y
end

-- Returns the current world-space region bounds.
function WorldRegionView:get_bounds()
  return self.min_x, self.min_y, self.max_x, self.max_y
end

-- Maps world coordinates onto the complete current canvas.
function WorldRegionView:begin()
  local canvas = love.graphics.getCanvas()
  assert(canvas ~= nil, "world region view requires an active canvas")

  local width, height = canvas:getDimensions()
  local world_width = self.max_x - self.min_x
  local world_height = self.max_y - self.min_y

  love.graphics.push()
  love.graphics.scale(width / world_width, height / world_height)
  love.graphics.translate(-self.min_x, -self.min_y)
end

-- Restores the transformation that existed before the world region was applied.
function WorldRegionView:finish()
  love.graphics.pop()
end

return WorldRegionView
