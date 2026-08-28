local EventActionBindings = {}
EventActionBindings.__index = EventActionBindings

-- Creates an empty collection of named runtime event action bindings.
function EventActionBindings.new()
  return setmetatable({
    actions = {}
  }, EventActionBindings)
end

-- Binds one serializable event action name to a runtime callback.
function EventActionBindings:bind(name, callback)
  assert(type(name) == "string", "event action name must be a string")
  assert(name ~= "", "event action name must not be empty")
  assert(type(callback) == "function", "event action callback must be a function")
  assert(self.actions[name] == nil, "event action is already bound: " .. name)

  self.actions[name] = callback
end

-- Returns whether one event action name has a runtime binding.
function EventActionBindings:has(name)
  return self.actions[name] ~= nil
end

-- Returns the runtime callback bound to one event action name.
function EventActionBindings:get(name)
  return self.actions[name]
end

return EventActionBindings
