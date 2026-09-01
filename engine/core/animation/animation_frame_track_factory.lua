local AnimationFrameTrack = require("engine.core.animation.animation_frame_track")

local AnimationFrameTrackFactory = {}

-- Creates a resource factory that pairs animation clips with one fixed sequence resource type.
function AnimationFrameTrackFactory.for_sequence_type(sequence_resource_type)
  assert(type(sequence_resource_type) == "string" and sequence_resource_type ~= "",
    "animation frame track factory requires a non-empty sequence resource type")

  return function(definition, context)
    assert(type(definition) == "table", "animation frame track definition must be a table")
    assert(context ~= nil and type(context.resolve_resource) == "function",
      "animation frame track factory requires resource resolution")

    local clip = context.resolve_resource("animation_clip", definition.clip)
    local sequence = context.resolve_resource(sequence_resource_type, definition.sequence)

    return AnimationFrameTrack.new(clip, sequence)
  end
end

return AnimationFrameTrackFactory
