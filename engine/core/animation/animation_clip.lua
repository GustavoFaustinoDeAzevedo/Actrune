local AnimationClip = {}
AnimationClip.__index = AnimationClip

-- Creates an immutable description of a frame-based animation clip.
function AnimationClip.new(options)
  options = options or {}

  local self = setmetatable({}, AnimationClip)
  self.frame_count = options.frame_count
  self.frame_duration = options.frame_duration or 0.1
  self.loop = options.loop ~= false

  assert(type(self.frame_count) == "number" and self.frame_count >= 1 and self.frame_count % 1 == 0,
    "animation clip frame_count must be a positive integer")
  assert(type(self.frame_duration) == "number" and self.frame_duration > 0,
    "animation clip frame_duration must be greater than zero")

  return self
end

-- Returns the number of frames contained in this clip.
function AnimationClip:get_frame_count()
  return self.frame_count
end

-- Returns the duration of one frame in seconds.
function AnimationClip:get_frame_duration()
  return self.frame_duration
end

-- Returns whether playback wraps after the final frame.
function AnimationClip:is_looping()
  return self.loop
end

return AnimationClip
