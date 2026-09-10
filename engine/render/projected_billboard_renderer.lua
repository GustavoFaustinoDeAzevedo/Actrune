local love = require "love"

local ProjectedBillboardRenderer = {}
ProjectedBillboardRenderer.__index = ProjectedBillboardRenderer

-- Creates a billboard renderer backed by an arbitrary world-to-screen projection.
function ProjectedBillboardRenderer.new(projection)
  assert(projection ~= nil and type(projection.project_world_point) == "function",
    "projected billboard renderer requires a world-to-screen projection")

  return setmetatable({
    projection = projection
  }, ProjectedBillboardRenderer)
end

-- Resolves one billboard world position from a fixed position or provider.
local function resolve_position(entry)
  if entry.position_provider ~= nil then
    local x, y = entry.position_provider()
    assert(type(x) == "number" and type(y) == "number", "billboard position provider must return numeric coordinates")
    return x, y
  end

  assert(type(entry.x) == "number" and type(entry.y) == "number", "billboard requires x and y or a position_provider")
  return entry.x, entry.y
end

-- Resolves absolute elevation from a live provider or a fixed value.
local function resolve_elevation(entry)
  local elevation = entry.elevation or 0

  if entry.elevation_provider ~= nil then
    assert(type(entry.elevation_provider) == "function",
      "billboard elevation provider must be a function")

    elevation = entry.elevation_provider()
  end

  assert(type(elevation) == "number"
    and elevation > -math.huge and elevation < math.huge,
    "billboard elevation must be finite")

  return elevation
end

-- Normalizes an angle to the signed range from -pi to pi.
local function normalize_angle(angle)
  return (angle + math.pi) % (math.pi * 2) - math.pi
end

-- Resolves how the current projection visually observes one oriented billboard.
local function resolve_relative_rotation(projection, entry, x, y)
  if entry.rotation_provider == nil then return nil end

  assert(type(entry.rotation_provider) == "function",
    "billboard rotation_provider must be a function")
  assert(type(projection.get_observation_angle) == "function",
    "directional billboard requires projection observation angle")

  local rotation = entry.rotation_provider()
  local observation_angle = projection:get_observation_angle(x, y)

  assert(type(rotation) == "number",
    "billboard rotation provider must return a numeric rotation")
  assert(type(observation_angle) == "number",
    "projection observation angle must be numeric")

  return normalize_angle(rotation - observation_angle)
end

-- Sorts projected billboards from farthest to nearest with deterministic ties.
local function compare_billboards(a, b)
  if a.projected.distance ~= b.projected.distance then return a.projected.distance > b.projected.distance end

  local order_a = a.entry.order or 0
  local order_b = b.entry.order or 0

  if order_a ~= order_b then return order_a < order_b end

  local id_a, id_b = tostring(a.entry.id or ""), tostring(b.entry.id or "")
  if id_a ~= id_b then return id_a < id_b end

  local y_a, y_b = a.entry.repeat_y or 0, b.entry.repeat_y or 0
  if y_a ~= y_b then return y_a < y_b end

  return (a.entry.repeat_x or 0) < (b.entry.repeat_x or 0)
end

-- Validates one visible projection result before it enters the drawing queue.
local function validate_visible_projection(projected, entry)
  local id = tostring(entry.id or "<unnamed>")

  assert(type(projected.x) == "number", "visible billboard projection requires numeric x for entry: " .. id)
  assert(type(projected.y) == "number", "visible billboard projection requires numeric y for entry: " .. id)
  assert(type(projected.distance) == "number", "visible billboard projection requires numeric distance for entry: " .. id)
  assert(projected.scale == nil or type(projected.scale) == "number" and projected.scale > 0,
    "billboard projection scale must be nil or greater than zero for entry: " .. id)
end

-- Projects, depth-sorts, and draws a collection of billboard entries.
function ProjectedBillboardRenderer:draw(entries, width, height, context)
  assert(type(entries) == "table", "projected billboard renderer entries must be a table")
  assert(type(width) == "number" and width > 0, "projected billboard renderer width must be greater than zero")
  assert(type(height) == "number" and height > 0, "projected billboard renderer height must be greater than zero")

  local visible = {}

  for _, entry in ipairs(entries) do
    assert(type(entry) == "table", "projected billboard entry must be a table")
    assert(entry.visual ~= nil and type(entry.visual.draw) == "function",
      "projected billboard entry requires a drawable visual")
    assert(entry.scale == nil or type(entry.scale) == "number" and entry.scale > 0,
      "projected billboard scale must be nil or greater than zero")

    if entry.enabled ~= false then
      local x, y = resolve_position(entry)
      local elevation = resolve_elevation(entry)
      local projected = self.projection:project_world_point(x, y, width, height, elevation)

      assert(type(projected) == "table", "world-to-screen projection must return a table")
      assert(type(projected.visible) == "boolean", "world-to-screen projection must return boolean visible")

      if projected.visible then
        validate_visible_projection(projected, entry)

        table.insert(visible, {
          entry = entry,
          projected = projected,
          relative_rotation = resolve_relative_rotation(self.projection, entry, x, y)
        })
      end
    end
  end

  table.sort(visible, compare_billboards)

  for _, item in ipairs(visible) do
    local entry = item.entry
    local projected = item.projected
    local scale = (projected.scale or 1) * (entry.scale or 1)

    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.translate(projected.x, projected.y)
    love.graphics.scale(scale)

    entry.visual:draw({
      entry = entry,
      projected = projected,
      projection = self.projection,
      relative_rotation = item.relative_rotation,
      context = context
    })

    love.graphics.pop()
  end
end

return ProjectedBillboardRenderer
