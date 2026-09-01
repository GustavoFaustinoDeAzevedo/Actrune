local AnimationFrameTrack = {}
AnimationFrameTrack.__index = AnimationFrameTrack

-- Creates a frame track by pairing one animation clip with an equally sized indexed sequence.
function AnimationFrameTrack.new(clip, sequence)
  assert(clip ~= nil and type(clip.get_frame_count) == "function",
    "animation frame track requires a clip exposing get_frame_count")
  assert(sequence ~= nil and type(sequence.get_count) == "function" and type(sequence.get) == "function",
    "animation frame track requires an indexed sequence exposing get_count and get")

  local frame_count = clip:get_frame_count()
  local item_count = sequence:get_count()

  assert(frame_count == item_count,
    "animation frame track count mismatch: clip has " ..
    frame_count .. " frame(s), sequence has " .. item_count .. " item(s)")

  return setmetatable({
    clip = clip,
    sequence = sequence
  }, AnimationFrameTrack)
end

-- Returns the timing clip associated with this frame track.
function AnimationFrameTrack:get_clip()
  return self.clip
end

-- Returns the number of synchronized frames in this track.
function AnimationFrameTrack:get_frame_count()
  return self.clip:get_frame_count()
end

-- Returns the payload associated with one animation frame.
function AnimationFrameTrack:get_frame(index)
  assert(type(index) == "number" and index % 1 == 0, "animation frame track index must be an integer")
  assert(index >= 1 and index <= self:get_frame_count(), "animation frame track index is out of range")
  return self.sequence:get(index)
end

return AnimationFrameTrack
