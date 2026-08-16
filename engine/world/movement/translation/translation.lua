local Translation = {}
Translation.__index = Translation

-- Creates a translation component that delegates spatial movement to a spatial mover.
function Translation.new(spatial_mover)
    assert(spatial_mover ~= nil, "spatial mover is required")

    local self = setmetatable({}, Translation)

    self.spatial_mover = spatial_mover

    return self
end

-- Translates the entity along a direction by the given distance.
function Translation:move(direction_x, direction_y, distance)
    local length = math.sqrt(
        direction_x * direction_x
        + direction_y * direction_y
    )

    if length == 0 or distance == 0 then
        return
    end

    direction_x = direction_x / length
    direction_y = direction_y / length

    self.spatial_mover:try_move(
        direction_x * distance,
        0
    )

    self.spatial_mover:try_move(
        0,
        direction_y * distance
    )
end

return Translation