local SpatialMover = {}
SpatialMover.__index = SpatialMover

-- Creates a spatial mover that moves an entity while checking a named collision shape.
function SpatialMover.new(world, entity, options)
    assert(world ~= nil, "world is required")
    assert(entity ~= nil, "entity is required")
    assert(type(options) == "table", "options must be a table")
    assert(
        type(options.source_shape) == "string",
        "source shape must be a string"
    )
    assert(
        type(options.target_shape) == "string",
        "target shape must be a string"
    )

    local self = setmetatable({}, SpatialMover)

    self.world = world
    self.entity = entity
    self.source_shape_name = options.source_shape
    self.target_shape_name = options.target_shape

    return self
end

-- Attempts to move the entity and restores its previous position when blocked.
function SpatialMover:try_move(dx, dy)
    local source_shape =
        self.entity:get_shape(self.source_shape_name)

    if source_shape == nil then
        return false, nil
    end

    local previous_x, previous_y =
        self.entity:get_position()

    self.entity.transform:translate(dx, dy)

    local collisions = self.world:query_shape(
        source_shape,
        self.entity.transform,
        self.target_shape_name
    )

    for _, other in ipairs(collisions) do
        if other ~= self.entity then
            self.entity:set_position(
                previous_x,
                previous_y
            )

            return false, other
        end
    end

    return true, nil
end

return SpatialMover