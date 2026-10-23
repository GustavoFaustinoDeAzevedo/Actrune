local MapLocationTracker = require("engine.world.maps.map_location_tracker")
local TransitionRunner = require("engine.core.transitions.transition_runner")

---@class MapCameraTransition: MapCameraTransitionFields
local MapCameraTransition = {}
MapCameraTransition.__index = MapCameraTransition

--- Retains each required map once for the current execution.
---@param self MapCameraTransition Current controller.
---@param map? table Optional region.
local function retain(self, map)
  if map == nil or self.held[map.id] then return end
  local release = self.retain_map(map.id)
  assert(type(release) == "function", "map retention must return a release function")
  self.releases[#self.releases + 1] = release
  self.held[map.id] = true
end

--- Selects the latest map and delegates position application to the configured style.
---@param self MapCameraTransition Current controller.
---@param effect? TransitionEffect Active effect; nil requests immediate recovery.
local function apply(self, effect)
  self.tracker:refresh()
  local map = self.tracker:get_map()
  self.bounds:select_map(map, 0, self.control.camera)
  self.apply_position(self.control, effect)
  self.presented_map = map
end

--- Releases all acquired capabilities, including when one cleanup callback fails.
---@param self MapCameraTransition Current controller.
---@param status TransitionStatus Terminal execution status.
local function finish(self, status)
  self.recover = status ~= "completed"
  local releases, first_error = self.releases, nil
  self.releases, self.held = {}, {}
  for index = #releases, 1, -1 do
    local ok, err = pcall(releases[index])
    if not ok and first_error == nil then first_error = tostring(err) end
  end
  if first_error ~= nil then error(first_error, 0) end
end

--- Coordinates map observation, temporary requirements and an injected camera style.
---@param options MapCameraTransitionOptions Camera composition dependencies.
---@return MapCameraTransition controller New controller with independent transition state.
function MapCameraTransition.new(options)
  assert(type(options.create_effect) == "function",
    "camera transition requires an effect factory")
  assert(type(options.apply_position) == "function",
    "camera transition requires position application")
  assert(type(options.retain_map) == "function",
    "camera transition requires map retention")
  assert(options.acquire == nil or type(options.acquire) == "function",
    "camera transition acquisition must be a function")
  local tracker = MapLocationTracker.new(options.bounds.configuration.layout, options.target)
  options.bounds.manual = true
  return setmetatable({
    control = options.control,
    bounds = options.bounds,
    tracker = tracker,
    create_effect = options.create_effect,
    apply_position = options.apply_position,
    retain_map = options.retain_map,
    acquire = options.acquire,
    presented_map = tracker:get_map(),
    releases = {},
    held = {},
    recover = false
  }, MapCameraTransition)
end

--- Reports active execution or pending recovery after cancellation or failure.
---@return boolean busy Whether another transition must wait.
function MapCameraTransition:is_busy()
  return self.recover or self.runner ~= nil and self.runner:get_status() == "running"
end

--- Returns the map selected by the last successful destination application.
---@return MapRegion? map Selected map, or nil outside the layout.
function MapCameraTransition:get_presented_map()
  return self.presented_map
end

--- Starts from an explicit source without resetting the current camera position.
---@param previous? MapRegion Source from this controller's layout.
---@return boolean started Whether the sampled destination differs from the source.
function MapCameraTransition:start(previous)
  assert(not self:is_busy(), "camera transition is already busy")
  assert(previous == nil or self.tracker.layout:get_map(previous.id) == previous,
    "camera transition source must belong to its layout")
  self.tracker:refresh()
  self.presented_map = previous
  if self.tracker:get_map() == previous then return false end

  local effect = self.create_effect()
  self.runner = TransitionRunner.new({
    effect = effect,
    on_begin = function()
      if self.acquire ~= nil then
        local release = self.acquire()
        assert(type(release) == "function",
          "transition acquisition must return a release function")
        self.releases[#self.releases + 1] = release
      end
      retain(self, self.presented_map)
      retain(self, self.tracker:get_map())
    end,
    apply_destination = function()
      self.tracker:refresh()
      retain(self, self.tracker:get_map())
      apply(self, effect)
    end,
    on_finish = function(status) finish(self, status) end
  })
  self.runner:start()
  self.runner:update(0)
  return true
end

--- Advances an execution, recovers framing, or observes the next map change.
---@param dt number Presentation time in seconds.
---@param simulation_dt? number Simulation time; zero while suspended.
function MapCameraTransition:update(dt, simulation_dt)
  self.tracker:refresh()
  if self.recover then
    apply(self)
    self.recover = false
    return
  end
  if self.runner ~= nil and self.runner:get_status() == "running" then
    self.runner:update(dt)
    return
  end
  if self.tracker:get_map() == self.presented_map then
    self.control:update(simulation_dt or dt)
    return
  end
  self:start(self.presented_map)
end

--- Draws only the active effect; world drawing remains owned by the renderer.
---@param context? any Rendering context supplied to custom effects.
function MapCameraTransition:draw(context)
  if self.runner ~= nil then self.runner:draw(context) end
end

--- Releases temporary state; the next update aligns framing with the current world.
---@return boolean cancelled Whether an active execution was cancelled.
function MapCameraTransition:cancel()
  return self.runner ~= nil and self.runner:cancel() or false
end

return MapCameraTransition
