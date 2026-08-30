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

-- Sorts projected billboards from farthest to nearest with deterministic ties.
local function compare_billboards(a, b)
  if a.projected.distance ~= b.projected.distance then return a.projected.distance > b.projected.distance end

  local order_a = a.entry.order or 0
  local order_b = b.entry.order or 0

  if order_a ~= order_b then return order_a < order_b end

  return tostring(a.entry.id or "") < tostring(b.entry.id or "")
end

-- Projects, depth-sorts, and draws a collection of vertical billboard entries.
function ProjectedBillboardRenderer:draw(entries, width, height, context)
  assert(type(entries) == "table", "projected billboard renderer entries must be a table")
  assert(type(width) == "number" and width > 0, "projected billboard renderer width must be greater than zero")
  assert(type(height) == "number" and height > 0, "projected billboard renderer height must be greater than zero")

  local visible = {}

  for _, entry in ipairs(entries) do
    assert(type(entry) == "table", "projected billboard entry must be a table")
    assert(type(entry.draw) == "function", "projected billboard entry requires a draw callback")

    local x, y = resolve_position(entry)
    local projected = self.projection:project_world_point(x, y, width, height)

    if projected.visible and entry.enabled ~= false then
      table.insert(visible, {
        entry = entry,
        projected = projected
      })
    end
  end

  table.sort(visible, compare_billboards)

  for _, item in ipairs(visible) do
    local entry = item.entry
    local projected = item.projected
    local scale = projected.scale * (entry.scale or 1)

    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.translate(projected.x + (entry.offset_x or 0), projected.y + (entry.offset_y or 0))
    love.graphics.scale(scale)

    entry.draw({
      entry = entry,
      projected = projected,
      projection = self.projection,
      context = context
    })

    love.graphics.pop()
  end
end

return ProjectedBillboardRenderer
