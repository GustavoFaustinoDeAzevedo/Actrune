local AnimationFrameTrackSet = require("engine.core.animation.animation_frame_track_set")

local AnimationFrameTrackSetFactory = {}

-- Creates a resource factory that resolves an ordered set of one fixed animation track resource type.
function AnimationFrameTrackSetFactory.for_track_type(track_resource_type)
  assert(type(track_resource_type) == "string" and track_resource_type ~= "",
    "animation frame track set factory requires a non-empty track resource type")

  return function(definition, context)
    assert(type(definition) == "table", "animation frame track set definition must be a table")
    assert(type(definition.tracks) == "table" and #definition.tracks > 0,
      "animation frame track set requires at least one track")
    assert(context ~= nil and type(context.resolve_resource) == "function",
      "animation frame track set factory requires resource resolution")

    local tracks = {}

    for index, name in ipairs(definition.tracks) do
      assert(type(name) == "string" and name ~= "",
        "animation frame track set resource name must be non-empty at index " .. index)
      tracks[index] = context.resolve_resource(track_resource_type, name)
    end

    return AnimationFrameTrackSet.new(tracks)
  end
end

return AnimationFrameTrackSetFactory
