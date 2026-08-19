local ContactMaterialResolver = {}
ContactMaterialResolver.__index = ContactMaterialResolver

-- Creates a contact material resolver using explicit property combination policies.
function ContactMaterialResolver.new(options)
  options = options or {}

  assert(
    type(options.restitution_combiner) == "function",
    "restitution combiner is required"
  )

  local self =
      setmetatable(
        {},
        ContactMaterialResolver
      )

  self.restitution_combiner =
      options.restitution_combiner

  self.default_restitution =
      options.default_restitution or 0

  return self
end

-- Resolves the effective restitution between two optional physical materials.
function ContactMaterialResolver:resolve_restitution(
    source_material,
    target_material
)
  local source_restitution = nil
  local target_restitution = nil

  if source_material ~= nil then
    source_restitution =
        source_material:get_restitution()
  end

  if target_material ~= nil then
    target_restitution =
        target_material:get_restitution()
  end

  if source_restitution == nil
      and target_restitution == nil
  then
    return self.default_restitution
  end

  if source_restitution == nil then
    return target_restitution
  end

  if target_restitution == nil then
    return source_restitution
  end

  return self.restitution_combiner(
    source_restitution,
    target_restitution
  )
end

return ContactMaterialResolver
