local Shape = {}
Shape.__index = Shape

-- Creates a base spatial shape with an optional local offset.
function Shape.new(options)
    options = options or {}

    local self = setmetatable({}, Shape)

    self.offset_x = options.offset_x or 0
    self.offset_y = options.offset_y or 0

    return self
end

-- Returns the local offset of this shape relative to its entity.
function Shape:get_offset()
    return self.offset_x, self.offset_y
end

return Shape