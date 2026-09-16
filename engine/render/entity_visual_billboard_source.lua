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
    entity_visuals = entity_visuals,
    entries = EntityVisualBillboardAdapter.create_all(entity_visuals)
  }, EntityVisualBillboardSource)
end

--- Appends active representations without rebuilding their entries.
---@param entries table[] Destination billboard list.
function EntityVisualBillboardSource:append_entries(entries)
  assert(type(entries) == "table",
    "entity visual billboard source destination must be a table")

  for index, entry in ipairs(self.entries) do
    if self.entity_visuals:get(index):get_entity():is_active() then
      entries[#entries + 1] = entry
    end
  end
end

return EntityVisualBillboardSource
