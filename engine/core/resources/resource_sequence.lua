local ResourceSequence = {}
ResourceSequence.__index = ResourceSequence

-- Creates an immutable ordered collection of resolved runtime resources.
function ResourceSequence.new(items)
  assert(type(items) == "table" and #items > 0, "resource sequence requires at least one item")

  local resolved = {}

  for index, item in ipairs(items) do
    assert(item ~= nil, "resource sequence item must not be nil at index " .. index)
    resolved[index] = item
  end

  return setmetatable({ items = resolved }, ResourceSequence)
end

-- Returns the number of resources contained in this sequence.
function ResourceSequence:get_count()
  return #self.items
end

-- Returns one resolved resource by its one-based sequence index.
function ResourceSequence:get(index)
  assert(type(index) == "number" and index % 1 == 0, "resource sequence index must be an integer")
  assert(index >= 1 and index <= #self.items, "resource sequence index is out of range")
  return self.items[index]
end

return ResourceSequence
