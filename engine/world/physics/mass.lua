local Mass = {}
Mass.__index = Mass

-- Creates a positive mass value for a dynamic physical body.
function Mass.new(value)
  assert(
    type(value) == "number",
    "mass must be a number"
  )

  assert(
    value > 0,
    "mass must be greater than zero"
  )

  local self = setmetatable({}, Mass)

  self.value = value

  return self
end

-- Returns the current mass value.
function Mass:get_value()
  return self.value
end

-- Returns the inverse mass used by impulse calculations.
function Mass:get_inverse()
  return 1 / self.value
end

-- Changes the current mass value.
function Mass:set_value(value)
  assert(
    type(value) == "number",
    "mass must be a number"
  )

  assert(
    value > 0,
    "mass must be greater than zero"
  )

  self.value = value
end

return Mass
