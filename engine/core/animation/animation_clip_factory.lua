local AnimationClip = require("engine.core.animation.animation_clip")

local AnimationClipFactory = {}

-- Creates one animation clip from serializable timing data.
function AnimationClipFactory.create(definition)
  assert(type(definition) == "table", "animation clip definition must be a table")
  assert(type(definition.frame_durations) == "table" and #definition.frame_durations > 0,
    "animation clip requires at least one frame duration")

  return AnimationClip.new({
    frame_durations = definition.frame_durations,
    loop = definition.loop ~= false
  })
end

return AnimationClipFactory
