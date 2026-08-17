local Value = {}
Value.__index = Value

-- Creates a value source that resolves to a configurable numeric value.
function Value.new(value)
    assert(type(value) == "number", "value must be a number")

    local self = setmetatable({}, Value)

    self.value = value

    return self
end

-- Resolves the current numeric value.
function Value:resolve()
    return self.value
end

-- Changes the numeric value returned by this source.
function Value:set_value(value)
    assert(type(value) == "number", "value must be a number")

    self.value = value
end

return Value
