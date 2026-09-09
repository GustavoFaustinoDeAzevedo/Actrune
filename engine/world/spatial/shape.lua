---@class Shape: ShapeFields
local Shape = {}
Shape.__index = Shape

--- Creates the shared data used by spatial shape implementations.
--- The offset is expressed in local entity coordinates.
---@param options? ShapeOptions Base shape configuration.
---@return Shape shape New base shape data.
function Shape.new(options)
    options = options or {}

    local self = setmetatable({}, Shape)

    self.material = options.material
    self.offset_x = options.offset_x or 0
    self.offset_y = options.offset_y or 0

    return self
end

--- Returns the local offset from the entity origin.
--- The entity transform is not applied by this method.
---@return number x Local X offset.
---@return number y Local Y offset.
function Shape:get_offset()
    return self.offset_x, self.offset_y
end

--- Assigns or clears the physical material used by collision responses.
--- Changing the material does not change the shape geometry.
---@param material any? New material, or nil to clear it.
function Shape:set_material(material)
    self.material = material
end

--- Returns the currently assigned physical material.
---@return any? material Physical material, or nil when none is assigned.
function Shape:get_material()
    return self.material
end

return Shape
