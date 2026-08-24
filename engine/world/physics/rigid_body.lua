local RigidBody = {}
RigidBody.__index = RigidBody

-- Creates a backend-independent rigid body configuration.
function RigidBody.new(options)
  options = options or {}

  local self = setmetatable({}, RigidBody)

  self.body_type = options.body_type or "static"
  self.shapes = {}

  for _, shape_name in ipairs(options.shapes or {}) do
    assert(type(shape_name) == "string", "rigid body shape name must be a string")
    table.insert(self.shapes, shape_name)
  end

  return self
end

-- Returns the rigid body's simulation type.
function RigidBody:get_body_type()
  return self.body_type
end

-- Returns the entity shapes participating in rigid body physics.
function RigidBody:get_shapes()
  return self.shapes
end

return RigidBody
