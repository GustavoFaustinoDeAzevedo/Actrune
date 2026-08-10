local Shape = require("engine.world.spatial.shape")

local PolygonShape = {}
PolygonShape.__index = PolygonShape

setmetatable(PolygonShape, {
    __index = Shape
})

-- Creates a polygon shape from a list of local-space points.
function PolygonShape.new(options)
    assert(type(options) == "table", "options must be a table")
    assert(type(options.points) == "table", "points must be a table")
    assert(#options.points >= 3, "polygon must have at least three points")

    local self = setmetatable(
        Shape.new(options),
        PolygonShape
    )

    self.points = options.points

    return self
end

-- Returns the number of sides defined by this polygon.
function PolygonShape:get_side_count()
    return #self.points
end

-- Converts this polygon's local points into world-space coordinates.
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

return PolygonShape