---@class ResidentMapCollection: ResidentMapCollectionFields
local ResidentMapCollection = {}
ResidentMapCollection.__index = ResidentMapCollection

--- Resolves authored map content to existing project entity instances.
--- Builds membership once; later movement does not change content ownership.
--- Entities remain live, while membership tables must be treated as read-only.
---@param layout MapLayout Layout containing map content identifiers.
---@param entities Entity[] Existing project entities in declaration order.
---@return ResidentMapCollection collection Resident content index.
function ResidentMapCollection.new(layout, entities)
  assert(layout ~= nil and type(layout.ordered_maps) == "table",
    "resident maps require a map layout")
  assert(type(entities) == "table", "resident maps require existing project entities")

  local by_id = {}
  for _, entity in ipairs(entities) do
    assert(type(entity) == "table" and type(entity.id) == "string" and entity.id ~= "",
      "resident map entities require non-empty identifiers")
    assert(by_id[entity.id] == nil, "duplicate resident entity: " .. entity.id)
    by_id[entity.id] = entity
  end

  local self = setmetatable({
    maps = {},
    owner_by_entity = {},
    shared_entities = {}
  }, ResidentMapCollection)

  for _, region in ipairs(layout.ordered_maps) do
    local resident = { region = region, entities = {} }
    self.maps[region.id] = resident

    for _, id in ipairs(region.entities) do
      local entity = by_id[id]
      assert(entity ~= nil, "map " .. region.id .. " references missing entity: " .. id)
      assert(self.owner_by_entity[entity] == nil,
        "entity is assigned more than once to map content: " .. id)

      resident.entities[#resident.entities + 1] = entity
      self.owner_by_entity[entity] = resident
    end
  end

  for _, entity in ipairs(entities) do
    if self.owner_by_entity[entity] == nil then
      self.shared_entities[#self.shared_entities + 1] = entity
    end
  end

  return self
end

--- Returns one resident map and its original entity instances.
---@param id string Map identifier.
---@return ResidentMap|nil map Read-only membership, or nil when unknown.
function ResidentMapCollection:get_map(id)
  return self.maps[id]
end

--- Returns the authored content owner, independently of the entity's current position.
---@param entity Entity Original entity instance.
---@return ResidentMap|nil map Owner, or nil when this instance has no map assignment.
function ResidentMapCollection:get_owner(entity)
  return self.owner_by_entity[entity]
end

--- Returns project entities without a map content assignment.
--- Includes travelling actors when they are omitted from map entity lists.
---@return Entity[] entities Read-only membership containing live entity instances.
function ResidentMapCollection:get_shared_entities()
  return self.shared_entities
end

return ResidentMapCollection