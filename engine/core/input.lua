local Input = {}
Input.__index = Input

-- Creates a new input manager with action bindings and runtime input states.
function Input.new()
    local self = setmetatable({}, Input)

    self.actions = {}

    self.down_keys = {}

    self.down_actions = {}
    self.pressed_actions = {}
    self.released_actions = {}

    return self
end

-- Binds a keyboard key to an input action.
function Input:bind_key(action, key)
    assert(type(action) == "string", "action must be a string")
    assert(type(key) == "string", "key must be a string")

    if self.actions[action] == nil then
        self.actions[action] = {}
    end

    self.actions[action][key] = true
end

-- Checks whether a keyboard key is bound to the given input action.
function Input:is_key_for_action(action, key)
    local bindings = self.actions[action]

    if bindings == nil then
        return false
    end

    return bindings[key] == true
end

-- Records a key press and updates every action bound to that key.
function Input:key_pressed(key)
    if self.down_keys[key] then
        return
    end

    self.down_keys[key] = true

    for action, bindings in pairs(self.actions) do
        if bindings[key] then
            if not self.down_actions[action] then
                self.pressed_actions[action] = true
            end

            self.down_actions[action] = true
        end
    end
end

-- Records a key release and updates every action bound to that key.
function Input:key_released(key)
    if not self.down_keys[key] then
        return
    end

    self.down_keys[key] = nil

    for action, bindings in pairs(self.actions) do
        if bindings[key] then
            local still_down = false

            for bound_key in pairs(bindings) do
                if self.down_keys[bound_key] then
                    still_down = true
                    break
                end
            end

            if not still_down then
                self.down_actions[action] = nil
                self.released_actions[action] = true
            end
        end
    end
end

-- Checks whether an action was pressed during the current frame.
function Input:is_action_pressed(action)
    return self.pressed_actions[action] == true
end

-- Checks whether an action is currently being held down.
function Input:is_action_down(action)
    return self.down_actions[action] == true
end

-- Checks whether an action was released during the current frame.
function Input:is_action_released(action)
    return self.released_actions[action] == true
end

-- Clears temporary pressed and released states at the end of a frame.
function Input:end_frame()
    self.pressed_actions = {}
    self.released_actions = {}
end

return Input