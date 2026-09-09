---@class WorldTopology: WorldTopologyFields
local WorldTopology = {}
WorldTopology.__index = WorldTopology

--- Validates one coordinate without accepting NaN or infinities.
---@param value number Coordinate or displacement.
local function require_finite(value)
  assert(type(value) == "number" and value > -math.huge and value < math.huge,
    "world topology coordinates must be finite")
end

--- Returns the shortest signed displacement on one periodic axis.
--- Exactly half a period selects the negative direction.
---@param delta number Requested displacement.
---@param size number Positive period.
---@return number delta Shortest displacement in [-size / 2, size / 2).
local function shortest_delta(delta, size)
  delta = delta % size
  if delta >= size * 0.5 then return delta - size end
  return delta
end

--- Creates rectangular map coordinates with independently optional X and Y loops.
--- Defines coordinate calculations only; does not move entities or repeat rendering.
---@param options WorldTopologyOptions Map origin, dimensions and looping axes.
---@return WorldTopology topology New map coordinate configuration.
function WorldTopology.new(options)
  assert(type(options) == "table", "world topology requires options")

  local min_x, min_y = options.min_x or 0, options.min_y or 0
  local width, height = options.width, options.height
  local loop_x, loop_y = options.loop_x, options.loop_y
  if loop_x == nil then loop_x = false end
  if loop_y == nil then loop_y = false end

  require_finite(min_x); require_finite(min_y)
  require_finite(width); require_finite(height)
  require_finite(min_x + width); require_finite(min_y + height)

  assert(width > 0 and height > 0, "world topology dimensions must be positive")
  assert(min_x + width > min_x and min_y + height > min_y,
    "world topology dimensions must produce distinct bounds")
  assert(type(loop_x) == "boolean" and type(loop_y) == "boolean",
    "world topology loop flags must be boolean")

  return setmetatable({
    min_x = min_x,
    min_y = min_y,
    width = width,
    height = height,
    loop_x = loop_x,
    loop_y = loop_y
  }, WorldTopology)
end

--- Returns the base rectangle; upper bounds are excluded on looping axes.
---@return number min_x Left boundary.
---@return number min_y Upper boundary.
---@return number max_x Right boundary.
---@return number max_y Lower boundary.
function WorldTopology:get_bounds()
  return self.min_x, self.min_y, self.min_x + self.width, self.min_y + self.height
end

--- Normalizes looping axes into the base rectangle without changing other axes.
--- Does not clamp non-looping axes, modify entities or affect Z.
---@param x number World X, possibly outside the base rectangle.
---@param y number World Y, possibly outside the base rectangle.
---@return number x Equivalent X in the configured coordinate space.
---@return number y Equivalent Y in the configured coordinate space.
function WorldTopology:wrap_position(x, y)
  require_finite(x); require_finite(y)

  if self.loop_x then x = self.min_x + (x - self.min_x) % self.width end
  if self.loop_y then y = self.min_y + (y - self.min_y) % self.height end

  return x, y
end

--- Returns the shortest displacement between two positions on the configured axes.
--- This is a distance/direction calculation, not a collision sweep or movement command.
---@param from_x number Origin X.
---@param from_y number Origin Y.
---@param to_x number Destination X.
---@param to_y number Destination Y.
---@return number dx Signed horizontal displacement.
---@return number dy Signed vertical displacement in the XY plane.
function WorldTopology:get_displacement(from_x, from_y, to_x, to_y)
  require_finite(from_x); require_finite(from_y)
  require_finite(to_x); require_finite(to_y)

  local dx, dy = to_x - from_x, to_y - from_y
  require_finite(dx); require_finite(dy)

  if self.loop_x then dx = shortest_delta(dx, self.width) end
  if self.loop_y then dy = shortest_delta(dy, self.height) end

  return dx, dy
end

--- Selects the equivalent target position nearest to a reference position.
--- The result may lie outside the base rectangle, allowing continuous camera tracking.
---@param x number Target X.
---@param y number Target Y.
---@param reference_x number Reference X, such as the current camera position.
---@param reference_y number Reference Y.
---@return number x Nearest equivalent target X.
---@return number y Nearest equivalent target Y.
function WorldTopology:get_nearest_position(x, y, reference_x, reference_y)
  local dx, dy = self:get_displacement(reference_x, reference_y, x, y)
  return reference_x + dx, reference_y + dy
end

return WorldTopology
