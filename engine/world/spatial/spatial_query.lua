local Geometry = require("engine.world.spatial.geometry")


local vector_dot = Geometry.dot
local point_on_segment = Geometry.point_on_segment
local segments_intersect = Geometry.segments_intersect
local segments_properly_intersect = Geometry.segments_properly_intersect
local segment_intersection_fraction = Geometry.moving_point_segment_fraction
local EPSILON = Geometry.EPSILON
local SpatialQuery = {}

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

-- Calculates the signed area of a polygon represented by flat world-space points.
local function polygon_signed_area(points)
    local area = 0

    for index = 1, #points, 2 do
        local next_index = index + 2

        if next_index > #points then
            next_index = 1
        end

        area = area
            + points[index]
            * points[next_index + 1]
            - points[next_index]
            * points[index + 1]
    end

    return area * 0.5
end

-- Calculates the outward unit normal of a polygon edge.
local function outward_edge_normal(
    start_x,
    start_y,
    end_x,
    end_y,
    winding
)
    local edge_x = end_x - start_x
    local edge_y = end_y - start_y

    local length =
        math.sqrt(
            edge_x * edge_x
            + edge_y * edge_y
        )

    if length <= EPSILON then
        return nil, nil
    end

    if winding >= 0 then
        return edge_y / length,
            -edge_x / length
    end

    return -edge_y / length,
        edge_x / length
end

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

-- Returns whether a point lies strictly inside a polygon rather than on its boundary.
local function point_strictly_inside_polygon(
    point_x,
    point_y,
    points
)
    local inside = false

    for index = 1, #points, 2 do
        local next_index =
            index + 2

        if next_index > #points then
            next_index = 1
        end

        local start_x =
            points[index]

        local start_y =
            points[index + 1]

        local end_x =
            points[next_index]

        local end_y =
            points[next_index + 1]

        if point_on_segment(
                point_x,
                point_y,
                start_x,
                start_y,
                end_x,
                end_y
            ) then
            return false
        end

        local crosses_y =
            (start_y > point_y)
            ~= (end_y > point_y)

        if crosses_y then
            local intersection_x =
                (end_x - start_x)
                * (point_y - start_y)
                / (end_y - start_y)
                + start_x

            if point_x < intersection_x then
                inside = not inside
            end
        end
    end

    return inside
end

-- Returns whether two polygons have overlapping interior areas.
local function polygons_overlap_strict(
    points_a,
    points_b
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

            if segments_properly_intersect(
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

    for index = 1, #points_a, 2 do
        if point_strictly_inside_polygon(
                points_a[index],
                points_a[index + 1],
                points_b
            ) then
            return true
        end
    end

    for index = 1, #points_b, 2 do
        if point_strictly_inside_polygon(
                points_b[index],
                points_b[index + 1],
                points_a
            ) then
            return true
        end
    end

    return false
end

-- Returns polygon points translated by a fraction of a displacement.
local function translate_points(
    points,
    dx,
    dy,
    fraction
)
    local translated = {}

    for index = 1, #points, 2 do
        table.insert(
            translated,
            points[index]
            + dx * fraction
        )

        table.insert(
            translated,
            points[index + 1]
            + dy * fraction
        )
    end

    return translated
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
