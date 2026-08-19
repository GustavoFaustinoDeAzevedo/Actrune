local PhysicalMaterial = {}
PhysicalMaterial.__index = PhysicalMaterial

-- Creates a physical material with configurable contact properties.
function PhysicalMaterial.new(options)
  options = options or {}

  local self = setmetatable({}, PhysicalMaterial)

  self.restitution = options.restitution or 0

  self.static_friction = options.static_friction or 0

  self.dynamic_friction = options.dynamic_friction or self.static_friction

  return self
end

-- Changes the material restitution coefficient.
function PhysicalMaterial:set_restitution(restitution)
  assert(
    type(restitution) == "number",
    "restitution must be a number"
  )

  assert(
    restitution >= 0,
    "restitution must be non-negative"
  )

  self.restitution = restitution
end

-- Returns the material restitution coefficient.
function PhysicalMaterial:get_restitution()
  return self.restitution
end

-- Changes the material static friction coefficient.
function PhysicalMaterial:set_static_friction(friction)
  assert(
    type(friction) == "number",
    "static friction must be a number"
  )

  assert(
    friction >= 0,
    "static friction must be non-negative"
  )

  self.static_friction = friction
end

-- Returns the material static friction coefficient.
function PhysicalMaterial:get_static_friction()
  return self.static_friction
end

-- Changes the material dynamic friction coefficient.
function PhysicalMaterial:set_dynamic_friction(friction)
  assert(
    type(friction) == "number",
    "dynamic friction must be a number"
  )

  assert(
    friction >= 0,
    "dynamic friction must be non-negative"
  )

  self.dynamic_friction = friction
end

-- Returns the material dynamic friction coefficient.
function PhysicalMaterial:get_dynamic_friction()
  return self.dynamic_friction
end

return PhysicalMaterial
