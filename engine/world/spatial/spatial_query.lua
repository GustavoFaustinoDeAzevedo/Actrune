local Geometry = require("engine.world.spatial.geometry")
local PolygonGeometry = require("engine.world.spatial.polygon_geometry")


local vector_dot = Geometry.dot
local segments_intersect = Geometry.segments_intersect
local segment_intersection_fraction = Geometry.moving_point_segment_fraction
local polygon_signed_area = PolygonGeometry.signed_area
local outward_edge_normal = PolygonGeometry.outward_edge_normal
local polygons_overlap_strict = PolygonGeometry.overlaps_strict
local translate_points = PolygonGeometry.translate_points
local EPSILON = Geometry.EPSILON
local SpatialQuery = {}


-- Keeps the earliest collision hit found during a polygon sweep.
local function keep_earliest_hit(
    current_hit,
    fraction,
    normal_x,
    normal_y
)
    if fraction == nil then
        return current_hit
    end

    if current_hit == nil
        or fraction < current_hit.fraction
    then
        return {
            fraction = fraction,
            normal_x = normal_x,
            normal_y = normal_y
        }
    end

    return current_hit
end

-- Adds a possible polygon sweep contact to a candidate list.
local function add_sweep_candidate(
    candidates,
    fraction,
    normal_x,
    normal_y
)
    if fraction == nil then
        return
    end

    table.insert(
        candidates,
        {
            fraction = fraction,
            normal_x = normal_x,
            normal_y = normal_y
        }
    )
end

-- Checks whether two polygon shapes overlap in world space.
function SpatialQuery.polygons_intersect(
    shape_a,
    transform_a,
    shape_b,
    transform_b
)
    local points_a = shape_a:get_world_points(transform_a)
    local points_b = shape_b:get_world_points(transform_b)

    local count_a = #points_a / 2
    local count_b = #points_b / 2

    for a = 1, count_a do
        local next_a = (a % count_a) + 1

        local ax = points_a[a * 2 - 1]
        local ay = points_a[a * 2]

        local bx = points_a[next_a * 2 - 1]
        local by = points_a[next_a * 2]

        for b = 1, count_b do
            local next_b = (b % count_b) + 1

            local cx = points_b[b * 2 - 1]
            local cy = points_b[b * 2]

            local dx = points_b[next_b * 2 - 1]
            local dy = points_b[next_b * 2]

            if segments_intersect(
                    ax, ay,
                    bx, by,
                    cx, cy,
                    dx, dy
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

-- Finds the earliest entering contact while translating one polygon against another.
function SpatialQuery.sweep_polygons(
    moving_shape,
    moving_transform,
    move_x,
    move_y,
    target_shape,
    target_transform
)
    if move_x == 0 and move_y == 0 then
        return nil
    end

    local moving_points =
        moving_shape:get_world_points(
            moving_transform
        )

    local target_points =
        target_shape:get_world_points(
            target_transform
        )

    local moving_winding =
        polygon_signed_area(
            moving_points
        )

    local target_winding =
        polygon_signed_area(
            target_points
        )

    local candidates = {}

    for moving_index = 1, #moving_points, 2 do
        local point_x =
            moving_points[moving_index]

        local point_y =
            moving_points[moving_index + 1]

        for target_index = 1, #target_points, 2 do
            local next_target_index =
                target_index + 2

            if next_target_index > #target_points then
                next_target_index = 1
            end

            local normal_x, normal_y =
                outward_edge_normal(
                    target_points[target_index],
                    target_points[target_index + 1],
                    target_points[next_target_index],
                    target_points[next_target_index + 1],
                    target_winding
                )

            if normal_x ~= nil
                and vector_dot(
                    move_x,
                    move_y,
                    normal_x,
                    normal_y
                ) < -EPSILON
            then
                local fraction =
                    segment_intersection_fraction(
                        point_x,
                        point_y,
                        move_x,
                        move_y,
                        target_points[target_index],
                        target_points[target_index + 1],
                        target_points[next_target_index],
                        target_points[next_target_index + 1]
                    )

                add_sweep_candidate(
                    candidates,
                    fraction,
                    normal_x,
                    normal_y
                )
            end
        end
    end

    for target_index = 1, #target_points, 2 do
        local point_x =
            target_points[target_index]

        local point_y =
            target_points[target_index + 1]

        for moving_index = 1, #moving_points, 2 do
            local next_moving_index =
                moving_index + 2

            if next_moving_index > #moving_points then
                next_moving_index = 1
            end

            local outward_x, outward_y =
                outward_edge_normal(
                    moving_points[moving_index],
                    moving_points[moving_index + 1],
                    moving_points[next_moving_index],
                    moving_points[next_moving_index + 1],
                    moving_winding
                )

            if outward_x ~= nil then
                local relative_x = -move_x
                local relative_y = -move_y

                if vector_dot(
                        relative_x,
                        relative_y,
                        outward_x,
                        outward_y
                    ) < -EPSILON
                then
                    local fraction =
                        segment_intersection_fraction(
                            point_x,
                            point_y,
                            relative_x,
                            relative_y,
                            moving_points[moving_index],
                            moving_points[moving_index + 1],
                            moving_points[next_moving_index],
                            moving_points[next_moving_index + 1]
                        )

                    add_sweep_candidate(
                        candidates,
                        fraction,
                        -outward_x,
                        -outward_y
                    )
                end
            end
        end
    end

    table.sort(
        candidates,
        function(left, right)
            return left.fraction
                < right.fraction
        end
    )

    local movement_length =
        math.sqrt(
            move_x * move_x
            + move_y * move_y
        )

    if movement_length <= EPSILON then
        return nil
    end

    local CONTACT_PROBE_DISTANCE =
        0.0001

    local probe_fraction =
        CONTACT_PROBE_DISTANCE
        / movement_length

    for _, candidate in ipairs(candidates) do
        local after_contact =
            candidate.fraction
            + probe_fraction

        local probe_points =
            translate_points(
                moving_points,
                move_x,
                move_y,
                after_contact
            )

        if polygons_overlap_strict(
                probe_points,
                target_points
            ) then
            return candidate
        end
    end

    return nil
end

return SpatialQuery
