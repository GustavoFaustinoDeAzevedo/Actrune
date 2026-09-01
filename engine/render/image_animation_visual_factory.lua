local ImageBillboardVisual = require("engine.render.image_billboard_visual")
local IndexedBillboardVisual = require("engine.render.indexed_billboard_visual")

local ImageAnimationVisualFactory = {}

-- Creates an indexed billboard visual from synchronized drawable image frames.
function ImageAnimationVisualFactory.create(track, index_provider)
  assert(track ~= nil and type(track.get_frame_count) == "function" and type(track.get_frame) == "function",
    "image animation visual factory requires an indexed frame track")
  assert(type(index_provider) == "function",
    "image animation visual factory requires an index provider")

  local visuals = {}

  for index = 1, track:get_frame_count() do
    local source = track:get_frame(index)

    assert(source ~= nil and type(source.get_dimensions) == "function" and type(source.draw) == "function",
      "image animation frame source must be drawable at index " .. index)

    visuals[index] = ImageBillboardVisual.new({
      source = source
    })
  end

  return IndexedBillboardVisual.new({
    visuals = visuals,
    index_provider = index_provider
  })
end

return ImageAnimationVisualFactory
