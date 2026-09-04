local BillboardSourceGroup = {}
BillboardSourceGroup.__index = BillboardSourceGroup

-- Creates a composable collection of static billboard entries and billboard sources.
function BillboardSourceGroup.new()
  return setmetatable({
    entries = {},
    sources = {}
  }, BillboardSourceGroup)
end

-- Adds one billboard entry owned directly by this group.
function BillboardSourceGroup:add_entry(entry)
  assert(type(entry) == "table",
    "billboard source group entry must be a table")

  self.entries[#self.entries + 1] = entry
end

-- Adds one source capable of contributing billboard entries.
function BillboardSourceGroup:add_source(source)
  assert(source ~= nil and type(source.append_entries) == "function",
    "billboard source group source must expose append_entries")

  self.sources[#self.sources + 1] = source
end

-- Collects all directly owned and externally provided billboard entries.
function BillboardSourceGroup:get_entries()
  local entries = {}

  for _, entry in ipairs(self.entries) do
    entries[#entries + 1] = entry
  end

  for _, source in ipairs(self.sources) do
    source:append_entries(entries)
  end

  return entries
end

return BillboardSourceGroup
