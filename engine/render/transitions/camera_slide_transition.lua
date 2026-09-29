---@class CameraSlideTransition: CameraSlideTransitionFields
local CameraSlideTransition = {}
CameraSlideTransition.__index = CameraSlideTransition

--- Resolves a live destination without moving the camera.
---@param self CameraSlideTransition Current movement.
---@return number x Destination X.
---@return number y Destination Y.
local function destination(self)
  local x, y = self.resolve_position()
  assert(type(x) == "number" and x > -math.huge and x < math.huge
    and type(y) == "number" and y > -math.huge and y < math.huge,
    "camera slide destination must be finite")
  return x, y
end

--- Creates a timed movement with an injected destination provider and easing curve.
---@param camera table Camera exposing get_position and set_position.
---@param resolve_position fun(): number, number Resolves the constrained live destination.
---@param duration number Finite non-negative seconds.
---@param curve fun(progress: number): number Weight in the inclusive range [0, 1].
---@return CameraSlideTransition effect Movement owned by one execution.
function CameraSlideTransition.new(camera, resolve_position, duration, curve)
  assert(type(duration) == "number" and duration >= 0 and duration < math.huge,
    "camera slide duration must be finite and non-negative")
  assert(type(resolve_position) == "function" and type(curve) == "function",
    "camera slide requires a destination provider and curve")
  local x, y = camera:get_position()
  return setmetatable({
    camera = camera,
    resolve_position = resolve_position,
    curve = curve,
    duration = duration,
    elapsed = 0,
    start_x = x,
    start_y = y
  }, CameraSlideTransition)
end

--- Validates the selected destination; zero duration applies it immediately.
function CameraSlideTransition:apply()
  local x, y = destination(self)
  if self.duration == 0 then self.camera:set_position(x, y) end
end

--- Requests destination selection before advancing movement; has no screen overlay.
--- Live target changes are sampled within the selected destination bounds.
---@param dt number Finite non-negative seconds, validated by TransitionRunner.
---@param applied boolean Whether destination selection succeeded.
---@return TransitionStep step Next execution instruction.
function CameraSlideTransition:update(dt, applied)
  if not applied then return self.duration == 0 and "done" or "apply" end
  self.elapsed = math.min(self.elapsed + dt, self.duration)
  local x, y = destination(self)
  if self.elapsed == self.duration then
    self.camera:set_position(x, y)
    return "done"
  end
  local weight = self.curve(self.elapsed / self.duration)
  assert(type(weight) == "number" and weight >= 0 and weight <= 1,
    "camera slide curve must return a finite weight between zero and one")
  self.camera:set_position(
    self.start_x + (x - self.start_x) * weight,
    self.start_y + (y - self.start_y) * weight
  )
  return "running"
end

return CameraSlideTransition
