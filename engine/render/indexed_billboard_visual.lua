local IndexedBillboardVisual = {}
IndexedBillboardVisual.__index = IndexedBillboardVisual

-- Creates a billboard visual that selects one child visual from an external index provider.
function IndexedBillboardVisual.new(options)
  options = options or {}

  assert(type(options.visuals) == "table" and #options.visuals > 0,
    "indexed billboard visual requires at least one visual")
  assert(type(options.index_provider) == "function",
    "indexed billboard visual requires an index provider")

  local self = setmetatable({}, IndexedBillboardVisual)
  self.visuals = options.visuals
  self.index_provider = options.index_provider

  for _, visual in ipairs(self.visuals) do
    assert(visual ~= nil and type(visual.draw) == "function",
      "indexed billboard visuals must contain drawable visuals")
  end

  return self
end

-- Draws the child visual selected by the current external index.
function IndexedBillboardVisual:draw(context)
  local index = self.index_provider(context)

  assert(type(index) == "number" and index % 1 == 0,
    "indexed billboard visual provider must return an integer index")
  assert(index >= 1 and index <= #self.visuals,
    "indexed billboard visual index is out of range: " .. tostring(index))

  self.visuals[index]:draw(context)
end

return IndexedBillboardVisual
