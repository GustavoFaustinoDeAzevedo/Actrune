local Translation = {}
Translation.__index = Translation

-- Creates a translation component that delegates displacement to a spatial mover.
function Translation.new(spatial_mover)
    assert(spatial_mover ~= nil, "spatial mover is required")

    local self = setmetatable({}, Translation)

    self.spatial_mover = spatial_mover

    return self
end

-- Translates the entity by the given world-space displacement.
function Translation:move(dx, dy)
    if dx == 0 and dy == 0 then
        return
    end

    self.spatial_mover:try_move(
        dx,
        0
    )

    self.spatial_mover:try_move(
        0,
        dy
    )
end

return Translation
