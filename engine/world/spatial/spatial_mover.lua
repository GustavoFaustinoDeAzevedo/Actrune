local SpatialMover = {}
SpatialMover.__index = SpatialMover

local MotionResult = require("engine.world.spatial.motion_result")

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

-- Attempts a spatial displacement and returns information about the resulting motion.
function SpatialMover:try_move(dx, dy)
    local result =
        MotionResult.new(dx, dy)

    local source_shape =
        self.entity:get_shape(
            self.source_shape_name
        )

    if source_shape == nil then
        return result
    end

    local previous_x, previous_y =
        self.entity:get_position()

    self.entity.transform:translate(
        dx,
        dy
    )

    local collisions =
        self.world:query_shape(
            source_shape,
            self.entity.transform,
            self.target_shape_name
        )

    local blocked = false

    for _, other_entity in ipairs(collisions) do
        if other_entity ~= self.entity then
            blocked = true

            result:add_collision(
                other_entity
            )
        end
    end

    if blocked then
        self.entity:set_position(
            previous_x,
            previous_y
        )

        return result
    end

    result:add_applied(
        dx,
        dy
    )

    return result
end

return SpatialMover
