local Shape = require("engine.world.spatial.shape")

---@class PolygonShape: Shape, PolygonShapeFields
local PolygonShape = {}
PolygonShape.__index = PolygonShape

setmetatable(PolygonShape, { __index = Shape })

--- Creates a polygon from ordered vertices in local entity space.
--- At least three vertices are required.
---@param options PolygonShapeOptions Polygon geometry and shared shape data.
---@return PolygonShape shape New polygon shape.
function PolygonShape.new(options)
    assert(type(options) == "table", "options must be a table")
    assert(type(options.points) == "table", "points must be a table")
    assert(#options.points >= 3, "polygon must have at least three points")

    local self = setmetatable(
        Shape.new(options),
        PolygonShape
    )
    ---@cast self PolygonShape

    self.points = options.points

    return self
end

--- Returns the geometry identifier used by spatial and physics systems.
---@return "polygon" geometry_type
function PolygonShape:get_geometry_type()
    return "polygon"
end

--- Returns the number of polygon edges.
--- A closed polygon has one edge for every vertex.
---@return integer count Number of sides.
function PolygonShape:get_side_count()
    return #self.points
end

--- Converts every local vertex into world coordinates.
--- Applies the shape offset followed by entity scale, rotation and position.
--- The flat result alternates X and Y values.
---@param transform Transform Transform owning this shape.
---@return WorldPointList points Alternating world coordinates.
function PolygonShape:get_world_points(transform)
    local world_points = {}

    for _, point in ipairs(self.points) do
        local local_x = point.x + self.offset_x
        local local_y = point.y + self.offset_y

        local world_x, world_y =
            transform:transform_point(local_x, local_y)

        table.insert(world_points, world_x)
        table.insert(world_points, world_y)
    end

    return world_points
end

--- Tests a world point against the polygon using local-space ray crossing.
--- The world point is converted through the inverse entity transform first.
--- Boundary behavior should not be used as the only collision contact rule.
---@param x number World X coordinate.
---@param y number World Y coordinate.
---@param transform Transform Transform owning this shape.
---@return boolean contains True when the ray-crossing test considers the point inside.
function PolygonShape:contains_point(x, y, transform)
    local local_x, local_y =
        transform:inverse_transform_point(x, y)

    local_x = local_x - self.offset_x
    local_y = local_y - self.offset_y

    local inside = false
    local previous = #self.points

    for current = 1, #self.points do
        local current_point = self.points[current]
        local previous_point = self.points[previous]

        local crosses_vertical_range =
            (current_point.y > local_y)
            ~= (previous_point.y > local_y)

        if crosses_vertical_range then
            local intersection_x =
                (previous_point.x - current_point.x)
                * (local_y - current_point.y)
                / (previous_point.y - current_point.y)
                + current_point.x

            if local_x < intersection_x then
                inside = not inside
            end
        end

        previous = current
    end

    return inside
end

return PolygonShape
