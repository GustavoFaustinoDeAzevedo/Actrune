---@class TransitionRunner: TransitionRunnerFields
local TransitionRunner = {}
TransitionRunner.__index = TransitionRunner

--- Ends execution before invoking cleanup, which is attempted at most once.
---@param self TransitionRunner Current execution.
---@param status TransitionStatus Requested terminal status.
---@return boolean ok Whether cleanup succeeded.
---@return any error Cleanup failure, when present.
local function finish(self, status)
  self.status = status
  local callback = self.on_finish
  self.on_finish = nil
  if callback == nil then return true end
  return pcall(callback, status, self.applied)
end

--- Attempts cleanup on failure and preserves both errors when cleanup also fails.
---@param self TransitionRunner Current execution.
---@param cause any Original failure.
local function fail(self, cause)
  local ok, cleanup_error = finish(self, "failed")
  self.busy = false
  if not ok then
    cause = tostring(cause) .. "\nTransition cleanup failed: " .. tostring(cleanup_error)
  end
  error(cause, 0)
end

--- Creates one execution with injected effect, destination application and lifecycle hooks.
--- Does not acquire resources or modify the destination until start/update are called.
--- Each execution owns its effect instance. Hooks must not reenter lifecycle methods.
---@param options TransitionRunnerOptions Execution dependencies.
---@return TransitionRunner runner New idle execution; create another runner to repeat it.
function TransitionRunner.new(options)
  assert(type(options) == "table", "transition runner requires options")
  local effect = options.effect
  assert(type(effect) == "table" and type(effect.update) == "function",
    "transition effect must expose update")
  assert(effect.draw == nil or type(effect.draw) == "function",
    "transition effect draw must be a function")
  assert(type(options.apply_destination) == "function",
    "transition runner requires destination application")
  assert(options.on_begin == nil or type(options.on_begin) == "function",
    "transition on_begin must be a function")
  assert(options.on_finish == nil or type(options.on_finish) == "function",
    "transition on_finish must be a function")
  assert(options.on_begin == nil or options.on_finish ~= nil,
    "transition on_begin requires on_finish cleanup")

  return setmetatable({
    effect = effect,
    apply_destination = options.apply_destination,
    on_begin = options.on_begin,
    on_finish = options.on_finish,
    status = "idle",
    applied = false,
    busy = false
  }, TransitionRunner)
end

--- Begins execution and acquires temporary state through the optional hook.
--- Cleanup is attempted even if the begin hook only completes part of its work.
function TransitionRunner:start()
  assert(not self.busy, "transition lifecycle must not be reentered")
  assert(self.status == "idle", "transition runner can only start once")
  self.status, self.busy = "running", true
  if self.on_begin ~= nil then
    local ok, err = pcall(self.on_begin)
    if not ok then fail(self, err) end
  end
  self.busy = false
end

--- Advances the effect and applies the destination at most once.
--- Running waits; apply requests the destination; done also applies it if still pending.
--- The effect receives successful application state on its next update.
--- Application failures are terminal and are not retried or automatically rolled back.
---@param dt number Finite non-negative elapsed seconds.
function TransitionRunner:update(dt)
  assert(not self.busy, "transition lifecycle must not be reentered")
  if self.status ~= "running" then return end
  self.busy = true

  if type(dt) ~= "number" or dt < 0 or dt >= math.huge or dt ~= dt then
    fail(self, "transition dt must be finite and non-negative")
  end

  local ok, step = pcall(self.effect.update, self.effect, dt, self.applied)
  if not ok then fail(self, step) end
  if step ~= "running" and step ~= "apply" and step ~= "done" then
    fail(self, "invalid transition step: " .. tostring(step))
  end

  if step ~= "running" and not self.applied then
    local applied, err = pcall(self.apply_destination)
    if not applied then fail(self, err) end
    self.applied = true
  end

  if step == "done" then
    local finished, err = finish(self, "completed")
    if not finished then fail(self, err) end
  end
  self.busy = false
end

--- Draws the active effect without advancing time or applying the destination.
--- Draw failures also end execution and attempt cleanup.
---@param context? any Rendering context forwarded unchanged to the effect.
function TransitionRunner:draw(context)
  assert(not self.busy, "transition lifecycle must not be reentered")
  if self.status ~= "running" or self.effect.draw == nil then return end
  self.busy = true
  local ok, err = pcall(self.effect.draw, self.effect, context)
  if not ok then fail(self, err) end
  self.busy = false
end

--- Cancels active execution and releases temporary state without undoing the destination.
---@return boolean cancelled Whether a running execution was cancelled.
function TransitionRunner:cancel()
  assert(not self.busy, "transition lifecycle must not be reentered")
  if self.status ~= "running" then return false end
  self.busy = true
  local ok, err = finish(self, "cancelled")
  if not ok then fail(self, err) end
  self.busy = false
  return true
end

--- Returns idle, running, completed, cancelled or failed.
---@return TransitionStatus status Current execution status.
function TransitionRunner:get_status()
  return self.status
end

--- Reports whether destination application returned successfully.
---@return boolean applied Whether the application callback completed.
function TransitionRunner:has_applied()
  return self.applied
end

return TransitionRunner
