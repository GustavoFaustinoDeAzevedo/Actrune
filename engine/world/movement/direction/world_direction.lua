local WorldDirection = {}
WorldDirection.__index = WorldDirection

-- Creates a world-relative direction resolver.
function WorldDirection.new()
    return setmetatable({}, WorldDirection)
end

-- Resolves directional input into a world-space movement vector.
function WorldDirection:resolve(input_x, input_y, transform)
    return input_x, input_y
end

return WorldDirection