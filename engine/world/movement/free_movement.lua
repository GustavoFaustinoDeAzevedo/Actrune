local FreeMovement = {}
FreeMovement.__index = FreeMovement

-- Creates a free-movement controller using a spatial mover and movement speed.
function FreeMovement.new(spatial_mover, options)
    assert(spatial_mover ~= nil, "spatial mover is required")

    options = options or {}

    local self = setmetatable({}, FreeMovement)

    self.spatial_mover = spatial_mover
    self.speed = options.speed or 120

    return self
end

-- Moves the entity using a direction vector while preserving constant movement speed.
function FreeMovement:move(direction_x, direction_y, dt)
    local length = math.sqrt(
        direction_x * direction_x
        + direction_y * direction_y
    )

    if length == 0 then
        return
    end

    direction_x = direction_x / length
    direction_y = direction_y / length

    local distance = self.speed * dt

    self.spatial_mover:try_move(
        direction_x * distance,
        0
    )

    self.spatial_mover:try_move(
        0,
        direction_y * distance
    )
end

return FreeMovement