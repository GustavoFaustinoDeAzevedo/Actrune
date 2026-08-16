local StepRotation = {}
StepRotation.__index = StepRotation

-- Creates a stepped rotation component that rotates by fixed angular increments.
function StepRotation.new(transform, options)
    assert(transform ~= nil, "transform is required")

    options = options or {}

    local self = setmetatable({}, StepRotation)

    self.transform = transform
    self.step_angle = options.step_angle or math.rad(90)

    return self
end

-- Rotates the transform by one fixed step in the given direction.
function StepRotation:turn(direction)
    if direction == 0 then
        return
    end

    local angle = direction * self.step_angle

    self.transform:rotate(angle)
end

return StepRotation