local Input = {}
Input.__index = Input

-- Creates a new input manager with an empty action binding table.
function Input.new()
    local self = setmetatable({}, Input)

    self.actions = {}

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

return Input