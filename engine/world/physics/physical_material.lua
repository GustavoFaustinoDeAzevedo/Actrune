local PhysicalMaterial = {}
PhysicalMaterial.__index = PhysicalMaterial

-- Creates a physical material with configurable contact properties.
function PhysicalMaterial.new(options)
  options = options or {}

  local self = setmetatable({}, PhysicalMaterial)

  self.restitution =
      options.restitution or 0

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

return PhysicalMaterial
