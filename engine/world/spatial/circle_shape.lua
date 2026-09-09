local Shape = require("engine.world.spatial.shape")

---@class CircleShape: Shape, CircleShapeFields
local CircleShape = {}
CircleShape.__index = CircleShape

setmetatable(CircleShape, {
  __index = Shape
})

--- Creates a circular shape in local entity space.
--- The radius must be positive.
--- Segments control the polygonal approximation used by spatial queries.
---@param options CircleShapeOptions Circle geometry and shared shape data.
---@return CircleShape shape New circular shape.
function CircleShape.new(options)
  assert(type(options) == "table", "options must be a table")
  assert(type(options.radius) == "number", "radius must be a number")
  assert(options.radius > 0, "radius must be positive")

  local self = setmetatable(Shape.new(options), CircleShape)
  ---@cast self CircleShape

  self.radius = options.radius
  self.segments = options.segments or 24

  return self
end

--- Returns the geometry identifier used by spatial and physics systems.
---@return "circle" geometry_type
function CircleShape:get_geometry_type()
  return "circle"
end

--- Returns the radius before the entity transform is applied.
---@return number radius Radius in local units.
function CircleShape:get_radius()
  return self.radius
end

--- Returns the transformed center in world coordinates.
--- Applies the shape offset and the supplied entity transform.
---@param transform Transform Transform owning this shape.
---@return number x World X coordinate.
---@return number y World Y coordinate.
function CircleShape:get_world_center(transform)
  return transform:transform_point(self.offset_x, self.offset_y)
end

--- Returns a polygonal approximation in world coordinates.
--- The flat result alternates X and Y values.
--- Entity scale and rotation are applied to every generated point.
---@param transform Transform Transform owning this shape.
---@return WorldPointList points Alternating world coordinates.
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

--- Returns whether a world point is inside or on the circle boundary.
--- The point is converted into local space before testing the radius.
---@param x number World X coordinate.
---@param y number World Y coordinate.
---@param transform Transform Transform owning this shape.
---@return boolean contains True when the point is inside or on the boundary.
function CircleShape:contains_point(x, y, transform)
  local local_x, local_y = transform:inverse_transform_point(x, y)
  local_x = local_x - self.offset_x
  local_y = local_y - self.offset_y

  return local_x * local_x + local_y * local_y <= self.radius * self.radius
end

return CircleShape
