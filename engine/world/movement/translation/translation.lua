local Translation = {}
Translation.__index = Translation

local MotionResult = require("engine.world.spatial.motion_result")

-- Creates a translation component that delegates displacement to a spatial mover.
function Translation.new(spatial_mover)
    assert(spatial_mover ~= nil, "spatial mover is required")

    local self = setmetatable({}, Translation)

    self.spatial_mover = spatial_mover

    return self
end

-- Translates the entity by the given world-space displacement and returns the resulting motion.
function Translation:move(dx, dy)
    local result =
        MotionResult.new(dx, dy)

    if dx ~= 0 then
        local horizontal_result =
            self.spatial_mover:try_move(
                dx,
                0
            )

        result:absorb(
            horizontal_result
        )
    end

    if dy ~= 0 then
        local vertical_result =
            self.spatial_mover:try_move(
                0,
                dy
            )

        result:absorb(
            vertical_result
        )
    end

    return result
end

return Translation
