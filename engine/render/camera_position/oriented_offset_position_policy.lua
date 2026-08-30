local OrientedOffsetPositionPolicy = {}
OrientedOffsetPositionPolicy.__index = OrientedOffsetPositionPolicy

-- Creates a position policy that offsets another position along an arbitrary orientation basis.
function OrientedOffsetPositionPolicy.new(policy, rotation_provider, options)
  options = options or {}

  assert(policy ~= nil and type(policy.resolve) == "function",
    "oriented offset position policy requires a resolvable position policy")
  assert(type(rotation_provider) == "function", "oriented offset position policy requires a rotation provider")

  return setmetatable({
    policy = policy,
    rotation_provider = rotation_provider,
    forward = options.forward or 0,
    right = options.right or 0
  }, OrientedOffsetPositionPolicy)
end

-- Changes the offset along the current forward direction.
function OrientedOffsetPositionPolicy:set_forward(forward)
  assert(type(forward) == "number", "oriented offset forward must be numeric")
  self.forward = forward
end

-- Changes the offset along the current right direction.
function OrientedOffsetPositionPolicy:set_right(right)
  assert(type(right) == "number", "oriented offset right must be numeric")
  self.right = right
end

-- Resolves the underlying position and applies the configured oriented offset.
function OrientedOffsetPositionPolicy:resolve(context)
  local x, y = self.policy:resolve(context)
  local rotation = self.rotation_provider(context)

  assert(type(rotation) == "number", "oriented offset rotation provider must return a number")

  local forward_x = math.sin(rotation)
  local forward_y = -math.cos(rotation)
  local right_x = math.cos(rotation)
  local right_y = math.sin(rotation)

  return x + forward_x * self.forward + right_x * self.right,
      y + forward_y * self.forward + right_y * self.right
end

return OrientedOffsetPositionPolicy
