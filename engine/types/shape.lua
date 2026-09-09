---@meta

---@alias WorldPointList number[] Alternating world coordinates: x1, y1, x2, y2, and so on.

---@class ShapeOptions
---@field material? any Optional physical material.
---@field offset_x? number Local X offset from the entity origin. Defaults to 0.
---@field offset_y? number Local Y offset from the entity origin. Defaults to 0.

---@class ShapeFields
---@field material any? Physical material used by collision responses.
---@field offset_x number Local X offset from the entity origin.
---@field offset_y number Local Y offset from the entity origin.
---@field get_geometry_type fun(self: Shape): string Returns the concrete geometry identifier.
---@field get_world_points fun(self: Shape, transform: Transform): WorldPointList Returns transformed polygon vertices.
---@field contains_point fun(self: Shape, x: number, y: number, transform: Transform): boolean Tests a world point.
