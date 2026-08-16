local FacingDirection = {}
FacingDirection.__index = FacingDirection

-- Creates a facing-relative direction resolver with optional strafing support.
function FacingDirection.new(options)
    options = options or {}

    local self = setmetatable({}, FacingDirection)

    self.allow_strafe = options.allow_strafe ~= false

    return self
end

-- Resolves directional input relative to the entity's current facing direction.
function FacingDirection:resolve(input_x, input_y, transform)
    local forward_x, forward_y =
        transform:get_forward()

    local right_x = -forward_y
    local right_y = forward_x

    local movement_x =
        forward_x * (-input_y)

    local movement_y =
        forward_y * (-input_y)

    if self.allow_strafe then
        movement_x =
            movement_x + right_x * input_x

        movement_y =
            movement_y + right_y * input_x
    end

    return movement_x, movement_y
end

return FacingDirection