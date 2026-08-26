local love = require "love"

local SpatialDebugRenderer = {}

-- Draws a named spatial shape belonging to an Actrune entity.
function SpatialDebugRenderer.draw_shape(entity, shape_name)
  if entity == nil then return end

  local shape = entity:get_shape(shape_name)
  if shape == nil then return end

  love.graphics.polygon("line", shape:get_world_points(entity.transform))
end

-- Draws an orientation marker using a circular entity shape.
function SpatialDebugRenderer.draw_circle_rotation(entity, shape_name)
  if entity == nil then return end

  local shape = entity:get_shape(shape_name)
  if shape == nil or type(shape.get_radius) ~= "function" then return end

  local radius = shape:get_radius()
  local angle = entity.transform.rotation
  local marker_x = entity.transform.x + math.cos(angle) * radius
  local marker_y = entity.transform.y + math.sin(angle) * radius

  love.graphics.line(entity.transform.x, entity.transform.y, marker_x, marker_y)
end

return SpatialDebugRenderer
