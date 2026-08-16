local ContinuousTranslation = {}
ContinuousTranslation.__index = ContinuousTranslation

-- Creates a continuous translation component that moves through world space at a fixed speed.
function ContinuousTranslation.new(spatial_mover, options)
    assert(spatial_mover ~= nil, "spatial mover is required")

    options = options or {}

    local self = setmetatable({}, ContinuousTranslation)

    self.spatial_mover = spatial_mover
    self.speed = options.speed or 120

    return self
end

-- Translates the entity continuously along a world-space direction.
function ContinuousTranslation:move(direction_x, direction_y, dt)
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

return ContinuousTranslation