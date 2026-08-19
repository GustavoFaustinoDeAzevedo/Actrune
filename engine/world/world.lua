local SpatialQuery = require("engine.world.spatial.spatial_query")
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

-- Returns all entities whose named shape contains the given world-space point.
function World:query_point(x, y, shape_name)
    assert(type(shape_name) == "string", "shape name must be a string")

    local results = {}

    for _, entity in pairs(self.entities) do
        local shape = entity:get_shape(shape_name)

        if shape and shape:contains_point(x, y, entity.transform) then
            table.insert(results, entity)
        end
    end

    return results
end

-- Returns all entities whose named polygon shape overlaps the given polygon shape.
function World:query_shape(shape, transform, shape_name)
    assert(shape ~= nil, "shape is required")
    assert(transform ~= nil, "transform is required")
    assert(type(shape_name) == "string", "shape name must be a string")

    local results = {}

    for _, entity in pairs(self.entities) do
        local target_shape = entity:get_shape(shape_name)

        if target_shape then
            local intersects =
                SpatialQuery.polygons_intersect(
                    shape,
                    transform,
                    target_shape,
                    entity.transform
                )

            if intersects then
                table.insert(results, entity)
            end
        end
    end

    return results
end

-- Finds entities and contact information intersected during a swept shape movement.
function World:sweep_shape(
    shape,
    transform,
    dx,
    dy,
    shape_name,
    ignored_entity
)
    local hits = {}

    for _, entity in pairs(self.entities) do
        if entity ~= ignored_entity then
            local target_shape =
                entity:get_shape(shape_name)

            if target_shape ~= nil then
                local hit =
                    SpatialQuery.sweep_polygons(
                        shape,
                        transform,
                        dx,
                        dy,
                        target_shape,
                        entity.transform
                    )

                if hit ~= nil then
                    table.insert(
                        hits,
                        {
                            entity = entity,

                            source_shape = shape,
                            target_shape = target_shape,

                            fraction = hit.fraction,
                            normal_x = hit.normal_x,
                            normal_y = hit.normal_y
                        }
                    )
                end
            end
        end
    end

    table.sort(
        hits,
        function(left, right)
            return left.fraction
                < right.fraction
        end
    )

    return hits
end

return World
