local Shape = {}
Shape.__index = Shape

-- Creates a base spatial shape with an optional local offset.
function Shape.new(options)
    options = options or {}

    local self = setmetatable({}, Shape)

    self.material = options.material
    self.offset_x = options.offset_x or 0
    self.offset_y = options.offset_y or 0

    return self
end

-- Returns the local offset of this shape relative to its entity.
function Shape:get_offset()
    return self.offset_x, self.offset_y
end

-- Sets the physical material associated with this shape.
function Shape:set_material(material)
    self.material = material
end

-- Returns the physical material associated with this shape.
function Shape:get_material()
    return self.material
end

return Shape
