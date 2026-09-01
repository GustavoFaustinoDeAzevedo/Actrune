local AnimationFrameTrackSet = {}
AnimationFrameTrackSet.__index = AnimationFrameTrackSet

-- Creates an ordered collection of animation frame tracks that share one timing clip.
function AnimationFrameTrackSet.new(tracks)
  assert(type(tracks) == "table" and #tracks > 0, "animation frame track set requires at least one track")

  local resolved = {}
  local clip = nil

  for index, track in ipairs(tracks) do
    assert(track ~= nil and type(track.get_clip) == "function",
      "animation frame track set item must expose get_clip at index " .. index)

    local track_clip = track:get_clip()

    if clip == nil then
      clip = track_clip
    else
      assert(track_clip == clip, "animation frame track set requires every track to share the same clip")
    end

    resolved[index] = track
  end

  return setmetatable({
    tracks = resolved,
    clip = clip
  }, AnimationFrameTrackSet)
end

-- Returns the shared timing clip used by every track in this set.
function AnimationFrameTrackSet:get_clip()
  return self.clip
end

-- Returns the number of synchronized tracks in this set.
function AnimationFrameTrackSet:get_count()
  return #self.tracks
end

-- Returns one synchronized track by its one-based index.
function AnimationFrameTrackSet:get(index)
  assert(type(index) == "number" and index % 1 == 0, "animation frame track set index must be an integer")
  assert(index >= 1 and index <= #self.tracks, "animation frame track set index is out of range")
  return self.tracks[index]
end

return AnimationFrameTrackSet
