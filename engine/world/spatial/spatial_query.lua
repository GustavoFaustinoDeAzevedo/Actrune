local SpatialQuery = {}

local EPSILON = 0.000001

-- Returns the signed cross product used to determine point orientation.
local function cross(ax, ay, bx, by, cx, cy)
    return
        (bx - ax) * (cy - ay)
        - (by - ay) * (cx - ax)
end

-- Checks whether a point lies on a line segment.
local function point_on_segment(px, py, ax, ay, bx, by)
    if math.abs(cross(ax, ay, bx, by, px, py)) > EPSILON then
        return false
    end

    return
        px >= math.min(ax, bx) - EPSILON
        and px <= math.max(ax, bx) + EPSILON
        and py >= math.min(ay, by) - EPSILON
        and py <= math.max(ay, by) + EPSILON
end

-- Checks whether two line segments intersect.
local function segments_intersect(
    ax, ay,
    bx, by,
    cx, cy,
    dx, dy
)
    local ab_c = cross(ax, ay, bx, by, cx, cy)
    local ab_d = cross(ax, ay, bx, by, dx, dy)

    local cd_a = cross(cx, cy, dx, dy, ax, ay)
    local cd_b = cross(cx, cy, dx, dy, bx, by)

    if
        ((ab_c > 0 and ab_d < 0) or (ab_c < 0 and ab_d > 0))
        and
        ((cd_a > 0 and cd_b < 0) or (cd_a < 0 and cd_b > 0))
    then
        return true
    end

    if math.abs(ab_c) <= EPSILON
        and point_on_segment(cx, cy, ax, ay, bx, by)
    then
        return true
    end

    if math.abs(ab_d) <= EPSILON
        and point_on_segment(dx, dy, ax, ay, bx, by)
    then
        return true
    end

    if math.abs(cd_a) <= EPSILON
        and point_on_segment(ax, ay, cx, cy, dx, dy)
    then
        return true
    end

    if math.abs(cd_b) <= EPSILON
        and point_on_segment(bx, by, cx, cy, dx, dy)
    then
        return true
    end

    return false
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

return SpatialQuery