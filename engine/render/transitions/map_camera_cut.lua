local MapLocationTracker = require("engine.world.maps.map_location_tracker")
local TransitionRunner = require("engine.core.transitions.transition_runner")

---@class MapCameraCut: MapCameraCutFields
local MapCameraCut = {}
MapCameraCut.__index = MapCameraCut

--- Retains each required map once for the current execution.
---@param self MapCameraCut Current controller.
---@param map? table Optional region.
local function retain(self, map)
  if map == nil or self.held[map.id] then return end
  local release = self.retain_map(map.id)
  assert(type(release) == "function", "map retention must return a release function")
  self.releases[#self.releases + 1] = release
  self.held[map.id] = true
end

--- Adopts the latest location without applying position or bounds smoothing.
---@param self MapCameraCut Current controller.
local function apply(self)
  self.tracker:refresh()
  local map = self.tracker:get_map()
  self.bounds:select_map(map, 0, self.control.camera)
  self.control:snap()
  self.presented_map = map
end

--- Releases all acquired capabilities, including when one cleanup callback fails.
---@param self MapCameraCut Current controller.
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

--- Creates the built-in cut style using injected effects, retention and optional suspension.
---@param options MapCameraCutOptions Camera composition dependencies.
---@return MapCameraCut controller New controller with independent transition state.
function MapCameraCut.new(options)
  assert(type(options.create_effect) == "function", "camera cut requires an effect factory")
  assert(type(options.retain_map) == "function", "camera cut requires map retention")
  assert(options.acquire == nil or type(options.acquire) == "function",
    "camera cut acquisition must be a function")
  local tracker = MapLocationTracker.new(options.bounds.configuration.layout, options.target)
  options.bounds.manual = true
  return setmetatable({
    control = options.control,
    bounds = options.bounds,
    tracker = tracker,
    create_effect = options.create_effect,
    retain_map = options.retain_map,
    acquire = options.acquire,
    presented_map = tracker:get_map(),
    releases = {},
    held = {},
    recover = false
  }, MapCameraCut)
end

--- Starts at a sampled map change and holds framing until the effect requests the cut.
--- Free simulation coalesces movement to the latest map when destination application occurs.
---@param dt number Presentation time in seconds.
---@param simulation_dt? number Simulation time; zero while suspended.
function MapCameraCut:update(dt, simulation_dt)
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

  self.runner = TransitionRunner.new({
    effect = self.create_effect(),
    on_begin = function()
      if self.acquire ~= nil then
        local release = self.acquire()
        assert(type(release) == "function", "transition acquisition must return a release function")
        self.releases[#self.releases + 1] = release
      end
      retain(self, self.presented_map)
      retain(self, self.tracker:get_map())
    end,
    apply_destination = function()
      self.tracker:refresh()
      retain(self, self.tracker:get_map())
      apply(self)
    end,
    on_finish = function(status) finish(self, status) end
  })
  self.runner:start()
  self.runner:update(0)
end

--- Draws only the active effect; world drawing remains owned by the renderer.
---@param context? any Rendering context supplied to custom effects.
function MapCameraCut:draw(context)
  if self.runner ~= nil then self.runner:draw(context) end
end

--- Releases temporary state; the next update aligns framing with the current world.
---@return boolean cancelled Whether an active execution was cancelled.
function MapCameraCut:cancel()
  return self.runner ~= nil and self.runner:cancel() or false
end

return MapCameraCut
