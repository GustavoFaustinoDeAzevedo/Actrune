local Shape = require("engine.world.spatial.shape")

local CircleShape = {}
CircleShape.__index = CircleShape

setmetatable(CircleShape, {
  __index = Shape
})

-- Creates a circular spatial shape in local entity space.
function CircleShape.new(options)
  assert(type(options) == "table", "options must be a table")
  assert(type(options.radius) == "number", "radius must be a number")
  assert(options.radius > 0, "radius must be positive")

  local self = setmetatable(Shape.new(options), CircleShape)

  self.radius = options.radius
  self.segments = options.segments or 24

  return self
end

-- Returns the primitive geometry type represented by this shape.
function CircleShape:get_geometry_type()
  return "circle"
end

-- Returns the circle radius in local space.
function CircleShape:get_radius()
  return self.radius
end

-- Returns the circle center in world space.
function CircleShape:get_world_center(transform)
  return transform:transform_point(self.offset_x, self.offset_y)
end

-- Returns a polygonal approximation of the circle in world space.
function CircleShape:get_world_points(transform)
  local points = {}

  for index = 0, self.segments - 1 do
    local angle = index / self.segments * math.pi * 2
    local local_x = self.offset_x + math.cos(angle) * self.radius
    local local_y = self.offset_y + math.sin(angle) * self.radius
    local world_x, world_y = transform:transform_point(local_x, local_y)

    table.insert(points, world_x)
    table.insert(points, world_y)
  end

  return points
end

-- Checks whether a world-space point lies inside the circle.
function CircleShape:contains_point(x, y, transform)
  local local_x, local_y = transform:inverse_transform_point(x, y)
  local_x = local_x - self.offset_x
  local_y = local_y - self.offset_y

  return local_x * local_x + local_y * local_y <= self.radius * self.radius
end

return CircleShape
