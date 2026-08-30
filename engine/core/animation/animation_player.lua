local AnimationPlayer = {}
AnimationPlayer.__index = AnimationPlayer

-- Creates a stateful player for one frame-based animation clip.
function AnimationPlayer.new(clip, options)
  options = options or {}

  assert(clip ~= nil, "animation player requires a clip")
  assert(type(clip.get_frame_count) == "function", "animation player clip must expose get_frame_count")
  assert(type(clip.get_frame_duration) == "function", "animation player clip must expose get_frame_duration")
  assert(type(clip.get_frame_start_time) == "function", "animation player clip must expose get_frame_start_time")
  assert(type(clip.get_total_duration) == "function", "animation player clip must expose get_total_duration")
  assert(type(clip.is_looping) == "function", "animation player clip must expose is_looping")

  local self = setmetatable({}, AnimationPlayer)
  self.clip = clip
  self.frame_index = options.frame_index or 1
  self.elapsed = 0
  self.playing = options.playing ~= false
  self.playback_rate = options.playback_rate or 1
  self.finished = false

  assert(self.frame_index >= 1 and self.frame_index <= clip:get_frame_count(),
    "animation player initial frame index is out of range")
  assert(type(self.playback_rate) == "number" and self.playback_rate >= 0,
    "animation player playback_rate must be zero or greater")

  return self
end

-- Returns the currently selected frame index.
function AnimationPlayer:get_frame_index()
  return self.frame_index
end

-- Returns the elapsed playback time within the current clip.
function AnimationPlayer:get_time()
  return self.clip:get_frame_start_time(self.frame_index) + self.elapsed
end

-- Returns normalized playback progress from zero to one.
function AnimationPlayer:get_progress()
  local total_duration = self.clip:get_total_duration()
  if total_duration <= 0 then return 0 end
  return math.min(1, self:get_time() / total_duration)
end

-- Returns normalized progress through the currently selected frame.
function AnimationPlayer:get_frame_progress()
  return math.min(1, self.elapsed / self.clip:get_frame_duration(self.frame_index))
end

-- Returns whether playback reached the end of a non-looping clip.
function AnimationPlayer:is_finished()
  return self.finished
end

-- Returns whether playback is currently advancing.
function AnimationPlayer:is_playing()
  return self.playing
end

-- Starts or resumes playback.
function AnimationPlayer:play()
  self.playing = true
  self.finished = false
end

-- Pauses playback without changing the current frame.
function AnimationPlayer:pause()
  self.playing = false
end

-- Restarts playback from the first frame.
function AnimationPlayer:restart()
  self.frame_index = 1
  self.elapsed = 0
  self.finished = false
  self.playing = true
end

-- Changes the current playback speed multiplier.
function AnimationPlayer:set_playback_rate(playback_rate)
  assert(type(playback_rate) == "number" and playback_rate >= 0,
    "animation player playback_rate must be zero or greater")
  self.playback_rate = playback_rate
end

-- Changes the active clip and optionally preserves the current playback state.
function AnimationPlayer:set_clip(clip, restart)
  assert(clip ~= nil and type(clip.get_frame_count) == "function",
    "animation player requires a valid clip")

  self.clip = clip

  if restart ~= false then
    self:restart()
  elseif self.frame_index > clip:get_frame_count() then
    self.frame_index = clip:get_frame_count()
    self.elapsed = 0
  end
end

-- Advances playback according to elapsed time.
function AnimationPlayer:update(dt)
  assert(type(dt) == "number" and dt >= 0, "animation player dt must be zero or greater")

  if not self.playing or self.finished or self.playback_rate == 0 then return end

  self.elapsed = self.elapsed + dt * self.playback_rate

  while self.elapsed >= self.clip:get_frame_duration(self.frame_index) do
    self.elapsed = self.elapsed - self.clip:get_frame_duration(self.frame_index)

    if self.frame_index < self.clip:get_frame_count() then
      self.frame_index = self.frame_index + 1
    elseif self.clip:is_looping() then
      self.frame_index = 1
    else
      self.frame_index = self.clip:get_frame_count()
      self.elapsed = self.clip:get_frame_duration(self.frame_index)
      self.playing = false
      self.finished = true
      break
    end
  end
end

return AnimationPlayer
