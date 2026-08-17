local RateValue = {}
RateValue.__index = RateValue

-- Creates a value source that produces an amount per second.
function RateValue.new(rate)
    assert(type(rate) == "number", "rate must be a number")

    local self = setmetatable({}, RateValue)

    self.rate = rate

    return self
end

-- Resolves the amount produced during the given elapsed time.
function RateValue:resolve(dt)
    return self.rate * dt
end

-- Changes the rate used to produce values over time.
function RateValue:set_rate(rate)
    assert(type(rate) == "number", "rate must be a number")

    self.rate = rate
end

return RateValue