local EntityVisualBillboardAdapter = require("engine.render.entity_visual_billboard_adapter")

local EntityVisualBillboardSource = {}
EntityVisualBillboardSource.__index = EntityVisualBillboardSource

-- Creates a billboard source backed by an indexed entity visual collection.
function EntityVisualBillboardSource.new(entity_visuals)
  assert(entity_visuals ~= nil and type(entity_visuals.get_count) == "function",
    "entity visual billboard source requires a collection exposing get_count")
  assert(type(entity_visuals.get) == "function",
    "entity visual billboard source requires a collection exposing get")

  return setmetatable({
    entries = EntityVisualBillboardAdapter.create_all(entity_visuals)
  }, EntityVisualBillboardSource)
end

-- Appends every billboard entry exposed by this source to a destination collection.
function EntityVisualBillboardSource:append_entries(entries)
  assert(type(entries) == "table",
    "entity visual billboard source destination must be a table")

  for _, entry in ipairs(self.entries) do
    entries[#entries + 1] = entry
  end
end

return EntityVisualBillboardSource
