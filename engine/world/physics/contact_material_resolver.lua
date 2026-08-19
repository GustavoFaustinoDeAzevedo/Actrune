local ContactMaterialResolver = {}
ContactMaterialResolver.__index = ContactMaterialResolver

-- Creates a contact material resolver using configurable property combination policies.
function ContactMaterialResolver.new(options)
  options = options or {}

  assert(
    type(options.restitution_combiner) == "function",
    "restitution combiner is required"
  )

  assert(
    type(options.static_friction_combiner) == "function",
    "static friction combiner is required"
  )

  assert(
    type(options.dynamic_friction_combiner) == "function",
    "dynamic friction combiner is required"
  )

  local self =
      setmetatable(
        {},
        ContactMaterialResolver
      )

  self.restitution_combiner = options.restitution_combiner
  self.static_friction_combiner = options.static_friction_combiner
  self.dynamic_friction_combiner = options.dynamic_friction_combiner
  self.default_restitution = options.default_restitution or 0
  self.default_static_friction = options.default_static_friction or 0
  self.default_dynamic_friction = options.default_dynamic_friction or 0

  return self
end

-- Combines one numeric property from two optional materials.
function ContactMaterialResolver:_combine_property(
    source_value,
    target_value,
    default_value,
    combiner
)
  if source_value == nil
      and target_value == nil
  then
    return default_value
  end

  if source_value == nil then
    return target_value
  end

  if target_value == nil then
    return source_value
  end

  return combiner(source_value, target_value)
end

-- Resolves the effective contact properties between two optional materials.
function ContactMaterialResolver:resolve(
    source_material,
    target_material
)
  local source_restitution = nil
  local target_restitution = nil

  local source_static_friction = nil
  local target_static_friction = nil

  local source_dynamic_friction = nil
  local target_dynamic_friction = nil

  if source_material ~= nil then
    source_restitution = source_material:get_restitution()
    source_static_friction = source_material:get_static_friction()
    source_dynamic_friction = source_material:get_dynamic_friction()
  end

  if target_material ~= nil then
    target_restitution = target_material:get_restitution()

    target_static_friction = target_material:get_static_friction()

    target_dynamic_friction = target_material:get_dynamic_friction()
  end

  return {
    restitution =
        self:_combine_property(
          source_restitution,
          target_restitution,
          self.default_restitution,
          self.restitution_combiner
        ),

    static_friction =
        self:_combine_property(
          source_static_friction,
          target_static_friction,
          self.default_static_friction,
          self.static_friction_combiner
        ),

    dynamic_friction =
        self:_combine_property(
          source_dynamic_friction,
          target_dynamic_friction,
          self.default_dynamic_friction,
          self.dynamic_friction_combiner
        )
  }
end

return ContactMaterialResolver
