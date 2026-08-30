local AnimationClip = {}
AnimationClip.__index = AnimationClip

-- Creates an immutable description of a frame-based animation clip.
function AnimationClip.new(options)
  options = options or {}

  local self = setmetatable({}, AnimationClip)
  self.frame_durations = {}

  if options.frame_durations ~= nil then
    assert(type(options.frame_durations) == "table" and #options.frame_durations > 0,
      "animation clip frame_durations must contain at least one duration")

    for index, duration in ipairs(options.frame_durations) do
      assert(type(duration) == "number" and duration > 0,
        "animation clip frame duration must be greater than zero at index " .. index)
      self.frame_durations[index] = duration
    end
  else
    local frame_count = options.frame_count
    local frame_duration = options.frame_duration or 0.1

    assert(type(frame_count) == "number" and frame_count >= 1 and frame_count % 1 == 0,
      "animation clip frame_count must be a positive integer")
    assert(type(frame_duration) == "number" and frame_duration > 0,
      "animation clip frame_duration must be greater than zero")

    for index = 1, frame_count do self.frame_durations[index] = frame_duration end
  end

  self.loop = options.loop ~= false
  self.total_duration = 0
  self.frame_start_times = {}

  for index, duration in ipairs(self.frame_durations) do
    self.frame_start_times[index] = self.total_duration
    self.total_duration = self.total_duration + duration
  end

  return self
end

-- Returns the number of frames contained in this clip.
function AnimationClip:get_frame_count()
  return #self.frame_durations
end

-- Returns the duration of one frame in seconds.
function AnimationClip:get_frame_duration(index)
  assert(type(index) == "number" and index >= 1 and index <= #self.frame_durations,
    "animation clip frame index is out of range")
  return self.frame_durations[index]
end

-- Returns the time at which one frame begins within the clip.
function AnimationClip:get_frame_start_time(index)
  assert(type(index) == "number" and index >= 1 and index <= #self.frame_durations,
    "animation clip frame index is out of range")
  return self.frame_start_times[index]
end

-- Returns the complete duration of the clip in seconds.
function AnimationClip:get_total_duration()
  return self.total_duration
end

-- Returns whether playback wraps after the final frame.
function AnimationClip:is_looping()
  return self.loop
end

return AnimationClip
