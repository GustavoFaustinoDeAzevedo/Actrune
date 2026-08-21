local Geometry = require("engine.world.spatial.geometry")
local PolygonGeometry = require("engine.world.spatial.polygon_geometry")
local PolygonSweep = require("engine.world.spatial.polygon_sweep")
local PolygonSeparation = require("engine.world.spatial.polygon_separation")
local PolygonContact = require("engine.world.spatial.polygon_contact")

local SpatialQuery = {}

-- Returns whether two polygon shapes intersect in world space.
function SpatialQuery.polygons_intersect(
    shape_a,
    transform_a,
    shape_b,
    transform_b
)
    local points_a =
        shape_a:get_world_points(
            transform_a
        )

    local points_b =
        shape_b:get_world_points(
            transform_b
        )

    for index_a = 1, #points_a, 2 do
        local next_a =
            index_a + 2

        if next_a > #points_a then
            next_a = 1
        end

        for index_b = 1, #points_b, 2 do
            local next_b =
                index_b + 2

            if next_b > #points_b then
                next_b = 1
            end

            if Geometry.segments_intersect(
                    points_a[index_a],
                    points_a[index_a + 1],
                    points_a[next_a],
                    points_a[next_a + 1],
                    points_b[index_b],
                    points_b[index_b + 1],
                    points_b[next_b],
                    points_b[next_b + 1]
                ) then
                return true
            end
        end
    end

    if shape_a:contains_point(
            points_b[1],
            points_b[2],
            transform_a
        ) then
        return true
    end

    if shape_b:contains_point(
            points_a[1],
            points_a[2],
            transform_b
        ) then
        return true
    end

    return false
end

-- Finds the earliest blocking contact while sweeping one polygon against another.
function SpatialQuery.sweep_polygons(
    moving_shape,
    moving_transform,
    move_x,
    move_y,
    target_shape,
    target_transform
)
    return PolygonSweep.sweep(
        moving_shape,
        moving_transform,
        move_x,
        move_y,
        target_shape,
        target_transform
    )
end

-- Returns whether two polygon interiors strictly overlap in world space.
function SpatialQuery.polygons_overlap_strict(shape_a, transform_a, shape_b, transform_b)
    local points_a = shape_a:get_world_points(transform_a)
    local points_b = shape_b:get_world_points(transform_b)

    return PolygonGeometry.overlaps_strict(points_a, points_b)
end

-- Finds a geometric translation that removes a strict overlap between two polygon shapes.
function SpatialQuery.find_polygon_separation(shape_a, transform_a, shape_b, transform_b)
    local points_a = shape_a:get_world_points(transform_a)
    local points_b = shape_b:get_world_points(transform_b)

    return PolygonSeparation.find(points_a, points_b)
end

-- Finds a persistent contact between two polygon shapes within the provided distance.
function SpatialQuery.find_polygon_contact(shape_a, transform_a, shape_b, transform_b, slop)
    local points_a = shape_a:get_world_points(transform_a)
    local points_b = shape_b:get_world_points(transform_b)

    return PolygonContact.find(points_a, points_b, slop)
end

return SpatialQuery
