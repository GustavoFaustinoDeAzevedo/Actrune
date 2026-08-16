local Rotation = {}
Rotation.__index = Rotation

-- Creates a rotation component that applies angular changes to a transform.
function Rotation.new(transform)
    assert(transform ~= nil, "transform is required")

    local self = setmetatable({}, Rotation)

    self.transform = transform

    return self
end

-- Rotates the transform by the given angle in radians.
function Rotation:turn(angle)
    if angle == 0 then
        return
    end

    self.transform:rotate(angle)
end

return Rotation