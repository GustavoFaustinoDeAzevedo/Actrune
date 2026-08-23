local MomentOfInertia = {}
MomentOfInertia.__index = MomentOfInertia

-- Creates a positive rotational inertia value.
function MomentOfInertia.new(value)
  assert(type(value) == "number" and value > 0, "moment of inertia must be positive")
  return setmetatable({ value = value }, MomentOfInertia)
end

-- Returns the current moment of inertia.
function MomentOfInertia:get_value()
  return self.value
end

-- Returns the inverse moment of inertia.
function MomentOfInertia:get_inverse()
  return 1 / self.value
end

-- Sets the current moment of inertia.
function MomentOfInertia:set_value(value)
  assert(type(value) == "number" and value > 0, "moment of inertia must be positive")
  self.value = value
end

return MomentOfInertia
