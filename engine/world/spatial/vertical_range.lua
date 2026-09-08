---@class VerticalRange: VerticalRangeFields
local VerticalRange = {}
VerticalRange.__index = VerticalRange

--- Creates a vertical interval relative to an optional elevation component.
--- Without an elevation component, lower and upper are absolute Z values.
--- Bounds must be finite and ordered; equal bounds are allowed.
---@param options? VerticalRangeOptions Interval configuration; omitted bounds default to zero.
---@return VerticalRange range New interval component.
function VerticalRange.new(options)
  options = options or {}

  local lower = options.lower or 0
  local upper = options.upper or 0
  local component = options.elevation_component

  assert(type(lower) == "number" and lower > -math.huge and lower < math.huge,
    "vertical range lower bound must be finite")
  assert(type(upper) == "number" and upper > -math.huge and upper < math.huge,
    "vertical range upper bound must be finite")
  assert(upper >= lower,
    "vertical range upper bound must not be below its lower bound")
  assert(component == nil or type(component) == "string" and component ~= "",
    "vertical range elevation component must be a non-empty name")

  return setmetatable({
    lower = lower,
    upper = upper,
    elevation_component = component
  }, VerticalRange)
end

--- Returns absolute Z bounds using the entity's current elevation.
--- Resolves the configured elevation component on each call.
--- Raises an error if that component is missing or cannot provide elevation.
--- Only calculates bounds; collision and interaction policies decide whether they overlap.
---@param entity? table Required when elevation_component is configured; otherwise ignored.
---@return number lower_z Absolute lower bound in world units.
---@return number upper_z Absolute upper bound in world units.
function VerticalRange:get_bounds(entity)
  local elevation = 0

  if self.elevation_component ~= nil then
    assert(entity ~= nil and type(entity.get_component) == "function",
      "vertical range requires an entity exposing get_component")

    local source = entity:get_component(self.elevation_component)

    assert(source ~= nil and type(source.get_elevation) == "function",
      "vertical range requires elevation component: " .. self.elevation_component)

    elevation = source:get_elevation()
  end

  assert(type(elevation) == "number"
    and elevation > -math.huge and elevation < math.huge,
    "vertical range elevation must be finite")

  return elevation + self.lower, elevation + self.upper
end

return VerticalRange
