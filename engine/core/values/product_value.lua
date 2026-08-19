local ProductValue = {}
ProductValue.__index = ProductValue

-- Creates a value source that multiplies the results of two other value sources.
function ProductValue.new(left, right)
  assert(left ~= nil, "left value source is required")
  assert(right ~= nil, "right value source is required")

  local self = setmetatable({}, ProductValue)

  self.left = left
  self.right = right

  return self
end

-- Resolves both value sources and multiplies their results.
function ProductValue:resolve(context)
  return self.left:resolve(context) * self.right:resolve(context)
end

return ProductValue
