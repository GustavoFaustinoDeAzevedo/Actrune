local AnimatedBillboardVisual = {}
AnimatedBillboardVisual.__index = AnimatedBillboardVisual

-- Creates an animated visual that advances through arbitrary drawable billboard frames.
function AnimatedBillboardVisual.new(options)
  options = options or {}

  assert(type(options.frames) == "table" and #options.frames > 0, "animated billboard visual requires at least one frame")

  local self = setmetatable({}, AnimatedBillboardVisual)
  self.frames = options.frames
  self.frame_duration = options.frame_duration or 0.1
  self.loop = options.loop ~= false
  self.playing = options.playing ~= false
  self.playback_rate = options.playback_rate or 1
  self.frame_index = options.frame_index or 1
  self.elapsed = 0
  self.finished = false

  assert(type(self.frame_duration) == "number" and self.frame_duration > 0,
    "animated billboard frame_duration must be greater than zero")
  assert(type(self.playback_rate) == "number" and self.playback_rate >= 0,
    "animated billboard playback_rate must be zero or greater")
  assert(type(self.frame_index) == "number" and self.frame_index >= 1 and self.frame_index <= #self.frames,
    "animated billboard initial frame index is out of range")

  for _, frame in ipairs(self.frames) do
    assert(frame ~= nil and type(frame.draw) == "function", "animated billboard frames must contain drawable visuals")
  end

  return self
end

-- Returns the currently displayed frame visual.
function AnimatedBillboardVisual:get_current_frame()
  return self.frames[self.frame_index]
end

-- Starts or resumes playback.
function AnimatedBillboardVisual:play()
  self.playing = true
  self.finished = false
end

-- Pauses playback without changing the current frame.
function AnimatedBillboardVisual:pause()
  self.playing = false
end

-- Restarts playback from the first frame.
function AnimatedBillboardVisual:restart()
  self.frame_index = 1
  self.elapsed = 0
  self.finished = false
  self.playing = true
end

-- Changes the animation playback rate.
function AnimatedBillboardVisual:set_playback_rate(playback_rate)
  assert(type(playback_rate) == "number" and playback_rate >= 0,
    "animated billboard playback_rate must be zero or greater")
  self.playback_rate = playback_rate
end

-- Advances the animation according to elapsed time.
function AnimatedBillboardVisual:update(dt, context)
  if not self.playing or self.finished or self.playback_rate == 0 then return end

  self.elapsed = self.elapsed + dt * self.playback_rate

  while self.elapsed >= self.frame_duration do
    self.elapsed = self.elapsed - self.frame_duration

    if self.frame_index < #self.frames then
      self.frame_index = self.frame_index + 1
    elseif self.loop then
      self.frame_index = 1
    else
      self.frame_index = #self.frames
      self.elapsed = 0
      self.playing = false
      self.finished = true
      break
    end
  end
end

-- Draws the currently selected animation frame.
function AnimatedBillboardVisual:draw(context)
  self:get_current_frame():draw(context)
end

return AnimatedBillboardVisual
