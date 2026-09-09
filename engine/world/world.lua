local SpatialQuery = require("engine.world.spatial.spatial_query")
local PeriodicQuery = require("engine.world.spatial.periodic_query")

---@class World: WorldFields
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

--- Sweeps the actual path without shortening it to the nearest periodic destination.
--- Keeps the earliest image contact per logical entity and ignores all self images.
---@param shape table Moving shape.
---@param transform Transform Original source transform.
---@param dx number Requested X travel.
---@param dy number Requested Y travel.
---@param shape_name string Target shape name.
---@param ignored_entity? Entity Entity excluded from all images.
---@param target_filter? fun(entity: Entity): boolean Optional logical target filter.
---@return WorldSweepHit[] hits Contacts sorted by travel fraction and entity identifier.
function World:sweep_shape(shape, transform, dx, dy, shape_name, ignored_entity, target_filter)
    assert(target_filter == nil or type(target_filter) == "function",
        "world sweep target filter must be a function")

    local t, hits = self.topology, {}
    local periodic = t ~= nil and (t.loop_x or t.loop_y)
    local bounds

    if periodic then
        bounds = PeriodicQuery.get_bounds(shape, transform)
        bounds.min_x, bounds.max_x = bounds.min_x + math.min(0, dx), bounds.max_x + math.max(0, dx)
        bounds.min_y, bounds.max_y = bounds.min_y + math.min(0, dy), bounds.max_y + math.max(0, dy)
    end

    for _, entity in pairs(self.entities) do
        local target = entity:get_shape(shape_name)

        if entity ~= ignored_entity and target ~= nil
            and (target_filter == nil or target_filter(entity)) then
            local first

            local function visit(image)
                local hit = SpatialQuery.sweep_polygons(shape, transform, dx, dy, target, image)
                if hit ~= nil and (first == nil or hit.fraction < first.fraction) then first = hit end
            end

            if periodic then
                ---@cast t WorldTopology
                PeriodicQuery.visit_transforms(t, bounds, target, entity.transform, visit)
            else
                visit(entity.transform)
            end

            if first ~= nil then
                hits[#hits + 1] = {
                    entity = entity,
                    source_shape = shape,
                    target_shape = target,
                    fraction = first.fraction,
                    normal_x = first.normal_x,
                    normal_y = first.normal_y,
                    point_x = first.point_x,
                    point_y = first.point_y
                }
            end
        end
    end

    table.sort(hits, function(a, b)
        if a.fraction ~= b.fraction then return a.fraction < b.fraction end
        return a.entity.id < b.entity.id
    end)

    return hits
end

--- Assigns the optional coordinate topology used by this world.
--- Does not reposition entities or change their elevation.
---@param topology? WorldTopology Map coordinate configuration; nil disables it.
function World:set_topology(topology)
    assert(topology == nil or type(topology.wrap_position) == "function",
        "world topology must expose wrap_position")

    self.topology = topology
end

--- Returns the coordinate topology currently assigned to this world.
---@return WorldTopology|nil topology Active map coordinate configuration.
function World:get_topology()
    return self.topology
end

--- Resolves equivalent coordinates inside the configured looping axes.
--- Does not modify entities, clamp non-looping axes or affect Z.
---@param x number Original planar X coordinate.
---@param y number Original planar Y coordinate.
---@return number x Resolved planar X coordinate.
---@return number y Resolved planar Y coordinate.
function World:wrap_position(x, y)
    if self.topology == nil then return x, y end
    return self.topology:wrap_position(x, y)
end

return World
