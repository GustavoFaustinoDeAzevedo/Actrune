local MapLocationTracker = require("engine.world.maps.map_location_tracker")

---@class RoutedMapCameraTransition: RoutedMapCameraTransitionFields
local RoutedMapCameraTransition = {}
RoutedMapCameraTransition.__index = RoutedMapCameraTransition

--- Releases completed controllers after capturing the map they actually presented.
---@param self RoutedMapCameraTransition Current route dispatcher.
local function collect(self)
  local active = self.active
  if active ~= nil and not active:is_busy() then
    self.presented_map = active:get_presented_map()
    self.active = nil
  end
end

--- Creates an independent route dispatcher using a resolved preset selector.
---@param options CameraTransitionContext Camera and narrow runtime capabilities.
---@param select_preset fun(previous: MapRegion?, current: MapRegion?): CameraTransitionPreset Directional lookup.
---@return RoutedMapCameraTransition controller Independent route state.
function RoutedMapCameraTransition.new(options, select_preset)
  assert(type(select_preset) == "function", "camera routes require preset selection")
  local tracker = MapLocationTracker.new(options.bounds.configuration.layout, options.target)
  options.bounds.manual = true
  return setmetatable({
    options = options,
    tracker = tracker,
    select_preset = select_preset,
    presented_map = tracker:get_map()
  }, RoutedMapCameraTransition)
end

--- Keeps one selected controller until completion, cancellation recovery or failure recovery.
--- Movement during an execution is sampled again after that execution has settled.
---@param dt number Presentation time in seconds.
---@param simulation_dt? number Simulation time; zero while suspended.
function RoutedMapCameraTransition:update(dt, simulation_dt)
  if self.active ~= nil then
    self.active:update(dt, simulation_dt)
    collect(self)
    return
  end

  self.tracker:refresh()
  local current = self.tracker:get_map()
  if current == self.presented_map then
    self.options.control:update(simulation_dt or dt)
    return
  end

  local preset = self.select_preset(self.presented_map, current)
  local controller = preset:create(self.options)
  assert(type(controller) == "table", "camera preset must create a controller")
  for _, method in ipairs({ "start", "update", "draw", "cancel", "is_busy", "get_presented_map" }) do
    assert(type(controller[method]) == "function",
      "routed camera controller requires " .. method)
  end
  self.active = controller
  controller:start(self.presented_map)
  collect(self)
end

--- Draws only the currently selected controller.
---@param context? any Rendering context forwarded to the selected controller.
function RoutedMapCameraTransition:draw(context)
  if self.active ~= nil then self.active:draw(context) end
end

--- Cancels the active execution; recovery finishes on the next update.
---@return boolean cancelled Whether an active execution was cancelled.
function RoutedMapCameraTransition:cancel()
  return self.active ~= nil and self.active:cancel() or false
end

return RoutedMapCameraTransition
