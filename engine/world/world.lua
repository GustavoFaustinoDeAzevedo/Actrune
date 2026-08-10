local World = {}
World.__index = World

-- Creates a new world responsible for storing and managing entities.
function World.new()
    local self = setmetatable({}, World)

    self.entities = {}

    return self
end

-- Adds an entity to the world using its identifier as the key.
function World:add_entity(entity)
    assert(entity ~= nil, "entity is required")
    assert(
        self.entities[entity.id] == nil,
        "entity id already exists: " .. entity.id
    )

    self.entities[entity.id] = entity
end

-- Removes an entity from the world by its identifier.
function World:remove_entity(id)
    self.entities[id] = nil
end

-- Returns the entity associated with the given identifier.
function World:get_entity(id)
    return self.entities[id]
end

-- Checks whether an entity with the given identifier exists in the world.
function World:has_entity(id)
    return self.entities[id] ~= nil
end

return World