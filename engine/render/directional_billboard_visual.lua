local DirectionalBillboardVisual = {}
DirectionalBillboardVisual.__index = DirectionalBillboardVisual

-- Creates a billboard visual that selects one child visual from the observed relative direction.
function DirectionalBillboardVisual.new(options)
  options = options or {}

  assert(type(options.directions) == "table" and #options.directions > 0,
    "directional billboard visual requires at least one direction")

  local self = setmetatable({}, DirectionalBillboardVisual)
  self.directions = options.directions
  self.angle_offset = options.angle_offset or 0

  for _, visual in ipairs(self.directions) do
    assert(visual ~= nil and type(visual.draw) == "function",
      "directional billboard directions must contain drawable visuals")
  end

  return self
end

-- Changes the angular alignment applied before selecting a directional visual.
function DirectionalBillboardVisual:set_angle_offset(angle)
  assert(type(angle) == "number", "directional billboard angle offset must be numeric")
  self.angle_offset = angle
end

-- Resolves the nearest directional visual for one relative viewing angle.
function DirectionalBillboardVisual:_resolve_visual(relative_rotation)
  local direction_count = #self.directions
  local full_rotation = math.pi * 2
  local sector = full_rotation / direction_count
  local normalized = (relative_rotation + self.angle_offset) % full_rotation
  local index = math.floor((normalized + sector * 0.5) / sector) % direction_count + 1

  return self.directions[index], index
end

-- Draws the child visual selected from the current relative viewing direction.
function DirectionalBillboardVisual:draw(context)
  assert(context ~= nil and type(context.relative_rotation) == "number",
    "directional billboard visual requires relative_rotation")

  local visual, direction_index = self:_resolve_visual(context.relative_rotation)

  visual:draw({
    entry = context.entry,
    projected = context.projected,
    projection = context.projection,
    relative_rotation = context.relative_rotation,
    direction_index = direction_index,
    context = context.context
  })
end

return DirectionalBillboardVisual
