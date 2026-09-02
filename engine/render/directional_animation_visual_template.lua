local DirectionalBillboardVisual = require("engine.render.directional_billboard_visual")

local DirectionalAnimationVisualTemplate = {}
DirectionalAnimationVisualTemplate.__index = DirectionalAnimationVisualTemplate

-- Creates a reusable directional visual template backed by synchronized animation tracks.
function DirectionalAnimationVisualTemplate.new(track_set, track_visual_factory, options)
  options = options or {}

  assert(track_set ~= nil and type(track_set.get_clip) == "function",
    "directional animation visual template requires a track set exposing get_clip")
  assert(type(track_set.get_count) == "function" and type(track_set.get) == "function",
    "directional animation visual template requires an indexed track set")
  assert(type(track_visual_factory) == "function",
    "directional animation visual template requires a track visual factory")

  local self = setmetatable({}, DirectionalAnimationVisualTemplate)
  self.track_set = track_set
  self.track_visual_factory = track_visual_factory
  self.angle_offset = options.angle_offset or 0

  assert(type(self.angle_offset) == "number",
    "directional animation visual template angle_offset must be numeric")

  return self
end

-- Returns the timing clip shared by every directional animation track.
function DirectionalAnimationVisualTemplate:get_clip()
  return self.track_set:get_clip()
end

-- Instantiates one directional visual using external per-instance playback state.
function DirectionalAnimationVisualTemplate:instantiate(options)
  options = options or {}

  assert(type(options.index_provider) == "function",
    "directional animation visual template requires an index provider")

  local directions = {}

  for index = 1, self.track_set:get_count() do
    directions[index] = self.track_visual_factory(
      self.track_set:get(index),
      options.index_provider
    )
  end

  return DirectionalBillboardVisual.new({
    directions = directions,
    angle_offset = self.angle_offset
  })
end

return DirectionalAnimationVisualTemplate
