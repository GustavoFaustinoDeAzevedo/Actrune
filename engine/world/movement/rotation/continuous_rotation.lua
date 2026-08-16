local ContinuousRotation = {}
ContinuousRotation.__index = ContinuousRotation

-- Creates a continuous rotation component with a configurable angular speed.
function ContinuousRotation.new(transform, options)
    assert(transform ~= nil, "transform is required")

    options = options or {}

    local self = setmetatable({}, ContinuousRotation)

    self.transform = transform
    self.speed = options.speed or math.rad(180)

    return self
end

-- Rotates continuously according to a signed turn direction.
function ContinuousRotation:turn(direction, dt)
    if direction == 0 then
        return
    end

    local angle = direction * self.speed * dt

    self.transform:rotate(angle)
end

return ContinuousRotation