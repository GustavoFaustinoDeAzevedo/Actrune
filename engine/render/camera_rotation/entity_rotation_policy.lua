local EntityRotationPolicy = {}
EntityRotationPolicy.__index = EntityRotationPolicy

-- Creates a rotation policy resolved from one entity with an optional angular offset.
function EntityRotationPolicy.new(entity, options)
  options = options or {}

  assert(entity ~= nil, "entity rotation policy requires an entity")
  assert(type(entity.get_rotation) == "function", "entity rotation policy target must expose get_rotation")

  return setmetatable({
    entity = entity,
    offset = options.offset or 0
  }, EntityRotationPolicy)
end

-- Changes the angular offset applied to the entity rotation.
function EntityRotationPolicy:set_offset(offset)
  assert(type(offset) == "number", "entity rotation policy offset must be numeric")
  self.offset = offset
end

-- Resolves the current entity rotation with the configured offset.
function EntityRotationPolicy:resolve(context)
  return self.entity:get_rotation() + self.offset
end

return EntityRotationPolicy
