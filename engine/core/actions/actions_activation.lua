local ActionActivation = {}
ActionActivation.__index = ActionActivation

-- Creates an action activation policy using the requested input state.
function ActionActivation.new(mode)
    assert(
        mode == "pressed"
        or mode == "down"
        or mode == "released",
        "invalid action activation mode"
    )

    local self = setmetatable({}, ActionActivation)

    self.mode = mode

    return self
end

-- Returns whether the action should activate for the current input state.
function ActionActivation:is_active(runtime, action)
    if self.mode == "pressed" then
        return runtime:is_action_pressed(action)
    end

    if self.mode == "released" then
        return runtime:is_action_released(action)
    end

    return runtime:is_action_down(action)
end

return ActionActivation