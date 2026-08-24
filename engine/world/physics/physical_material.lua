local PhysicalMaterial = {}
PhysicalMaterial.__index = PhysicalMaterial

-- Creates a physical material containing arbitrary user-defined properties.
function PhysicalMaterial.new(properties)
  properties = properties or {}

  assert(type(properties) == "table", "physical material properties must be a table")

  local self = setmetatable({
    properties = {}
  }, PhysicalMaterial)

  for name, value in pairs(properties) do self.properties[name] = value end

  return self
end

-- Changes or creates an arbitrary material property.
function PhysicalMaterial:set(name, value)
  assert(type(name) == "string", "material property name must be a string")
  self.properties[name] = value
end

-- Returns a material property or a fallback value when it is not defined.
function PhysicalMaterial:get(name, fallback)
  local value = self.properties[name]
  if value == nil then return fallback end
  return value
end

-- Removes an arbitrary material property.
function PhysicalMaterial:remove(name)
  assert(type(name) == "string", "material property name must be a string")
  self.properties[name] = nil
end

-- Returns whether the material explicitly defines a property.
function PhysicalMaterial:has(name)
  return self.properties[name] ~= nil
end

-- Changes the material restitution coefficient.
function PhysicalMaterial:set_restitution(restitution)
  assert(type(restitution) == "number", "restitution must be a number")
  assert(restitution >= 0, "restitution must be non-negative")
  self:set("restitution", restitution)
end

-- Returns the material restitution coefficient.
function PhysicalMaterial:get_restitution()
  return self:get("restitution", 0)
end

-- Changes the material static friction coefficient.
function PhysicalMaterial:set_static_friction(friction)
  assert(type(friction) == "number", "static friction must be a number")
  assert(friction >= 0, "static friction must be non-negative")
  self:set("static_friction", friction)
end

-- Returns the material static friction coefficient.
function PhysicalMaterial:get_static_friction()
  return self:get("static_friction", 0)
end

-- Changes the material dynamic friction coefficient.
function PhysicalMaterial:set_dynamic_friction(friction)
  assert(type(friction) == "number", "dynamic friction must be a number")
  assert(friction >= 0, "dynamic friction must be non-negative")
  self:set("dynamic_friction", friction)
end

-- Returns the material dynamic friction coefficient.
function PhysicalMaterial:get_dynamic_friction()
  return self:get("dynamic_friction", self:get_static_friction())
end

return PhysicalMaterial
