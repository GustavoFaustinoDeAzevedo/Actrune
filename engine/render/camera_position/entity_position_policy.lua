local EntityPositionPolicy = {}
EntityPositionPolicy.__index = EntityPositionPolicy

-- Creates a position policy that resolves from one entity with an optional offset.
function EntityPositionPolicy.new(entity, options)
  options = options or {}

  assert(entity ~= nil, "entity position policy requires an entity")
  assert(type(entity.get_position) == "function", "entity position policy target must expose get_position")

  return setmetatable({
    entity = entity,
    offset_x = options.offset_x or 0,
    offset_y = options.offset_y or 0
  }, EntityPositionPolicy)
end

-- Resolves the current entity position with the configured offset.
function EntityPositionPolicy:resolve(context)
  local x, y = self.entity:get_position()
  return x + self.offset_x, y + self.offset_y
end

return EntityPositionPolicy
