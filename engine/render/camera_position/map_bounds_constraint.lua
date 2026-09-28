local AxisAlignedBoundsConstraint = require("engine.render.camera_position.axis_aligned_bounds_constraint")
local MapLocationTracker = require("engine.world.maps.map_location_tracker")

---@class MapBoundsConstraint: MapBoundsConstraintFields
local MapBoundsConstraint = {}
MapBoundsConstraint.__index = MapBoundsConstraint

--- Creates independent camera state using the target's planar map location.
--- Initial bounds apply immediately; fallback must be a validated, read-only rectangle.
---@param configuration MapCameraBounds Shared map framing configuration.
---@param entity Entity Camera target, independent from map activity observers.
---@param options? MapBoundsConstraintOptions Global fallback and fixed axis settings.
---@return MapBoundsConstraint constraint Position constraint owned by one camera.
function MapBoundsConstraint.new(configuration, entity, options)
  options = options or {}
  local tracker = MapLocationTracker.new(configuration.layout, entity)
  local map = tracker:get_map()
  local bounds = configuration:get_bounds(map and map.id) or options.fallback
  local initial = bounds or { min_x = 0, min_y = 0, max_x = 0, max_y = 0 }

  return setmetatable({
    configuration = configuration,
    manual = options.manual == true,
    tracker = tracker,
    fallback = options.fallback,
    current_bounds = bounds,
    entry_bounds = { min_x = 0, min_y = 0, max_x = 0, max_y = 0 },
    constraint = AxisAlignedBoundsConstraint.new({
      min_x = initial.min_x,
      min_y = initial.min_y,
      max_x = initial.max_x,
      max_y = initial.max_y,
      constrain_x = options.constrain_x,
      constrain_y = options.constrain_y
    })
  }, MapBoundsConstraint)
end

--- Seeds a return from unrestricted tracking with bounds containing the current view.
---@param self MapBoundsConstraint Constraint returning to finite bounds.
---@param bounds CameraBounds Destination rectangle.
---@param camera table Camera exposing position, viewport, zoom and rotation.
local function include_current_view(self, bounds, camera)
  local x, y = camera:get_position()
  local _, _, width, height = camera:get_viewport()
  local zoom, rotation = camera:get_zoom(), camera:get_rotation()
  local cosine, sine = math.abs(math.cos(rotation)), math.abs(math.sin(rotation))
  local half_x = (width * cosine + height * sine) * 0.5 / zoom
  local half_y = (width * sine + height * cosine) * 0.5 / zoom
  local entry = self.entry_bounds
  entry.min_x, entry.min_y = math.min(bounds.min_x, x - half_x), math.min(bounds.min_y, y - half_y)
  entry.max_x, entry.max_y = math.max(bounds.max_x, x + half_x), math.max(bounds.max_y, y + half_y)
  self.constraint:set_bounds(entry, 0)
end

--- Selects bounds explicitly; zero duration also finishes an existing bounds transition.
---@param map? table Region from this configuration's layout; nil selects fallback.
---@param duration number Transition duration in seconds.
---@param camera table Camera used when returning from unrestricted tracking.
function MapBoundsConstraint:select_map(map, duration, camera)
  assert(map == nil or self.configuration.layout:get_map(map.id) == map,
    "camera bounds require a map from their layout")
  local bounds = self.configuration:get_bounds(map and map.id) or self.fallback
  if bounds ~= nil and (bounds ~= self.current_bounds or duration == 0) then
    if self.current_bounds == nil and duration > 0 then
      include_current_view(self, bounds, camera)
    end
    self.constraint:set_bounds(bounds, duration)
  end
  self.current_bounds = bounds
end

--- Advances selected bounds; automatic mode selects them from the target's XY location.
---@param x number Requested camera X.
---@param y number Requested camera Y.
---@param context CameraBoundsResolveContext Camera geometry and elapsed time.
---@return number x Resolved camera X.
---@return number y Resolved camera Y.
function MapBoundsConstraint:resolve(x, y, context)
  assert(context ~= nil and context.camera ~= nil, "map camera bounds require context.camera")
  if not self.manual then
    self.tracker:refresh()
    self:select_map(self.tracker:get_map(), self.configuration.duration, context.camera)
  end
  if self.current_bounds == nil then return x, y end
  return self.constraint:resolve(x, y, context)
end

return MapBoundsConstraint
