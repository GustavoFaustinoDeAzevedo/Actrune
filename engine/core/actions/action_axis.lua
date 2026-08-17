local ActionAxis = {}
ActionAxis.__index = ActionAxis

-- Creates an action axis from negative and positive actions using an activation policy.
function ActionAxis.new(options)
  assert(options ~= nil, "options are required")
  assert(options.activation ~= nil, "activation is required")

  local self = setmetatable({}, ActionAxis)

  self.negative_action = options.negative_action
  self.positive_action = options.positive_action
  self.activation = options.activation

  return self
end

-- Resolves the current axis value from its configured actions.
function ActionAxis:resolve(runtime)
  local value = 0

  if self.negative_action ~= nil
      and self.activation:is_active(
        runtime,
        self.negative_action
      )
  then
    value = value - 1
  end

  if self.positive_action ~= nil
      and self.activation:is_active(
        runtime,
        self.positive_action
      )
  then
    value = value + 1
  end

  return value
end

return ActionAxis
