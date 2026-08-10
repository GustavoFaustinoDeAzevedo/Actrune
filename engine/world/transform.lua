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

return Transform