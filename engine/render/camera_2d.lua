local love = require "love"

local Camera2D = {}
Camera2D.__index = Camera2D

-- Creates a 2D camera describing a world-space view and optional screen viewport.
function Camera2D.new(options)
  options = options or {}

  local self = setmetatable({}, Camera2D)
  self.x = options.x or 0
  self.y = options.y or 0
  self.rotation = options.rotation or 0
  self.zoom = options.zoom or 1
  self.viewport_x = options.viewport_x or 0
  self.viewport_y = options.viewport_y or 0
  self.viewport_width = options.viewport_width
  self.viewport_height = options.viewport_height

  assert(self.zoom > 0, "camera zoom must be greater than zero")

  return self
end

-- Returns the effective viewport, using the current window size when dimensions are not explicit.
function Camera2D:get_viewport()
  local window_width, window_height = love.graphics.getDimensions()
  return self.viewport_x, self.viewport_y, self.viewport_width or window_width, self.viewport_height or window_height
end

-- Changes the camera position in world space.
function Camera2D:set_position(x, y)
  self.x = x
  self.y = y
end

-- Returns the camera position in world space.
function Camera2D:get_position()
  return self.x, self.y
end

-- Changes the camera rotation in radians.
function Camera2D:set_rotation(rotation)
  self.rotation = rotation
end

-- Returns the camera rotation in radians.
function Camera2D:get_rotation()
  return self.rotation
end

-- Changes the camera zoom factor.
function Camera2D:set_zoom(zoom)
  assert(type(zoom) == "number" and zoom > 0, "camera zoom must be greater than zero")
  self.zoom = zoom
end

-- Changes the screen viewport used by this camera.
function Camera2D:set_viewport(x, y, width, height)
  assert(type(x) == "number" and type(y) == "number", "camera viewport position must be numeric")
  assert(type(width) == "number" and width > 0, "camera viewport width must be greater than zero")
  assert(type(height) == "number" and height > 0, "camera viewport height must be greater than zero")

  self.viewport_x = x
  self.viewport_y = y
  self.viewport_width = width
  self.viewport_height = height
end

-- Converts a world-space point into screen-space coordinates.
function Camera2D:world_to_screen(x, y)
  local viewport_x, viewport_y, viewport_width, viewport_height = self:get_viewport()
  local relative_x = x - self.x
  local relative_y = y - self.y
  local cos_rotation = math.cos(self.rotation)
  local sin_rotation = math.sin(self.rotation)
  local rotated_x = relative_x * cos_rotation + relative_y * sin_rotation
  local rotated_y = -relative_x * sin_rotation + relative_y * cos_rotation

  return viewport_x + viewport_width * 0.5 + rotated_x * self.zoom,
      viewport_y + viewport_height * 0.5 + rotated_y * self.zoom
end

-- Converts a screen-space point into world-space coordinates.
function Camera2D:screen_to_world(x, y)
  local viewport_x, viewport_y, viewport_width, viewport_height = self:get_viewport()
  local local_x = (x - viewport_x - viewport_width * 0.5) / self.zoom
  local local_y = (y - viewport_y - viewport_height * 0.5) / self.zoom
  local cos_rotation = math.cos(self.rotation)
  local sin_rotation = math.sin(self.rotation)
  local world_x = local_x * cos_rotation - local_y * sin_rotation
  local world_y = local_x * sin_rotation + local_y * cos_rotation

  return self.x + world_x, self.y + world_y
end

-- Applies the camera viewport and world-to-screen transform to subsequent drawing.
function Camera2D:begin()
  local viewport_x, viewport_y, viewport_width, viewport_height = self:get_viewport()

  love.graphics.push("all")
  love.graphics.setScissor(viewport_x, viewport_y, viewport_width, viewport_height)
  love.graphics.translate(viewport_x + viewport_width * 0.5, viewport_y + viewport_height * 0.5)
  love.graphics.scale(self.zoom)
  love.graphics.rotate(-self.rotation)
  love.graphics.translate(-self.x, -self.y)
end

-- Restores the graphics state that existed before this camera was applied.
function Camera2D:finish()
  love.graphics.pop()
end

return Camera2D
