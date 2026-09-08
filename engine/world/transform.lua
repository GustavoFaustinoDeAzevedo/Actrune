---@class Transform: TransformFields
local Transform = {}
Transform.__index = Transform

--- Creates a planar transform containing position, rotation and scale.
--- This transform has no Z coordinate; entity elevation is stored separately.
---@param options? TransformOptions Initial transform values.
---@return Transform transform New planar transform.
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

--- Replaces the current planar position.
--- Does not change rotation, scale or entity elevation.
---@param x number New X coordinate.
---@param y number New Y coordinate.
function Transform:set_position(x, y)
    self.x = x
    self.y = y
end

--- Adds a signed displacement to the current planar position.
---@param dx number Displacement along X.
---@param dy number Displacement along Y.
function Transform:translate(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
end

--- Replaces planar rotation.
---@param rotation number New angle in radians.
function Transform:set_rotation(rotation)
    self.rotation = rotation
end

--- Converts a point from local space to world space.
--- Applies scale, then rotation, then position.
---@param x number Local X coordinate.
---@param y number Local Y coordinate.
---@return number world_x World X coordinate.
---@return number world_y World Y coordinate.
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

--- Converts a point from world space to local space.
--- Reverses position, rotation and scale in that order.
--- Both scale axes must be nonzero for a valid inverse.
---@param x number World X coordinate.
---@param y number World Y coordinate.
---@return number local_x Local X coordinate.
---@return number local_y Local Y coordinate.
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

--- Returns the normalized planar direction represented by the current rotation.
--- Rotation 0 points along positive X.
---@return number x Forward direction along X.
---@return number y Forward direction along Y.
function Transform:get_forward()
    return math.cos(self.rotation), math.sin(self.rotation)
end

--- Adds a signed angle to the current rotation.
---@param angle number Rotation delta in radians.
function Transform:rotate(angle)
    self.rotation = self.rotation + angle
end

return Transform
