local DeltaTimeValue = {}
DeltaTimeValue.__index = DeltaTimeValue

-- Creates a value source that resolves to the current frame delta time.
function DeltaTimeValue.new()
  return setmetatable({}, DeltaTimeValue)
end

-- Resolves the current frame delta time from the provided context.
function DeltaTimeValue:resolve(context)
  assert(context ~= nil, "value context is required")
  assert(type(context.dt) == "number", "context dt is required")

  return context.dt
end

return DeltaTimeValue
