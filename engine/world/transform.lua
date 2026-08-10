local Transform = {}
Transform.__index = Transform

-- Creates a new transform representing a position, rotation, and scale in 2D space.
function Transform.new(options)
    options = options or {}

    local self = setmetatable({}, Transform)

    self.x = options.x or 0
    self.y = options.y or 0
    self.rotation = options.rotation or 0

    self.scale_x = options.scale_x or 1
    self.scale_y = options.scale_y or 1

    return self
end

-- Changes the transform position to the given coordinates.
function Transform:set_position(x, y)
    self.x = x
    self.y = y
end

-- Moves the transform by the given offset.
function Transform:translate(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
end

-- Changes the transform rotation in radians.
function Transform:set_rotation(rotation)
    self.rotation = rotation
end

-- Converts a local-space point into world-space coordinates.
function Transform:transform_point(x, y)
    local scaled_x = x * self.scale_x
    local scaled_y = y * self.scale_y

    local cos_rotation = math.cos(self.rotation)
    local sin_rotation = math.sin(self.rotation)

    local rotated_x =
        scaled_x * cos_rotation
        - scaled_y * sin_rotation

    local rotated_y =
        scaled_x * sin_rotation
        + scaled_y * cos_rotation

    return
        self.x + rotated_x,
        self.y + rotated_y
end

-- Converts a world-space point into coordinates local to this transform.
function Transform:inverse_transform_point(x, y)
    local translated_x = x - self.x
    local translated_y = y - self.y

    local cos_rotation = math.cos(-self.rotation)
    local sin_rotation = math.sin(-self.rotation)

    local rotated_x =
        translated_x * cos_rotation
        - translated_y * sin_rotation

    local rotated_y =
        translated_x * sin_rotation
        + translated_y * cos_rotation

    return
        rotated_x / self.scale_x,
        rotated_y / self.scale_y
end

return Transform