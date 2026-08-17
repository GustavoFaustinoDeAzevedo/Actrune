local FacingDirection = {}
FacingDirection.__index = FacingDirection

-- Creates a facing-relative direction resolver.
function FacingDirection.new()
    return setmetatable({}, FacingDirection)
end

-- Resolves a two-dimensional input vector relative to the entity's facing direction.
function FacingDirection:resolve(input_x, input_y, transform)
    local forward_x, forward_y =
        transform:get_forward()

    local right_x = -forward_y
    local right_y = forward_x

    local movement_x =
        right_x * input_x
        + forward_x * (-input_y)

    local movement_y =
        right_y * input_x
        + forward_y * (-input_y)

    return movement_x, movement_y
end

return FacingDirection
