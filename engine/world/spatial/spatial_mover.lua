local MotionResult =
    require("engine.world.spatial.motion_result")

local SpatialMover = {}
SpatialMover.__index = SpatialMover

local MOTION_EPSILON = 0.00001

-- Creates a spatial mover for an entity and its collision shapes.
function SpatialMover.new(world, entity, options)
    assert(world ~= nil, "world is required")
    assert(entity ~= nil, "entity is required")

    options = options or {}

    local self = setmetatable({}, SpatialMover)

    self.world = world
    self.entity = entity

    self.source_shape_name =
        options.source_shape

    self.target_shape_name =
        options.target_shape

    return self
end

-- Attempts a displacement and moves up to the first spatial collision.
function SpatialMover:try_move(dx, dy)
    local result =
        MotionResult.new(dx, dy)

    if dx == 0 and dy == 0 then
        return result
    end

    local source_shape =
        self.entity:get_shape(
            self.source_shape_name
        )

    if source_shape == nil then
        return result
    end

    local hits =
        self.world:sweep_shape(
            source_shape,
            self.entity.transform,
            dx,
            dy,
            self.target_shape_name,
            self.entity
        )

    if #hits == 0 then
        self.entity.transform:translate(
            dx,
            dy
        )

        result:add_applied(
            dx,
            dy
        )

        return result
    end

    local collision_fraction =
        hits[1].fraction

    local movement_length =
        math.sqrt(
            dx * dx
            + dy * dy
        )

    local fraction_margin = 0

    if movement_length > 0 then
        fraction_margin =
            MOTION_EPSILON
            / movement_length
    end

    local safe_fraction =
        math.max(
            0,
            collision_fraction
            - fraction_margin
        )

    local applied_x =
        dx * safe_fraction

    local applied_y =
        dy * safe_fraction

    self.entity.transform:translate(
        applied_x,
        applied_y
    )

    result:add_applied(
        applied_x,
        applied_y
    )

    for _, hit in ipairs(hits) do
        if math.abs(
                hit.fraction
                - collision_fraction
            ) <= MOTION_EPSILON then
            result:add_contact(
                hit.entity,
                hit.normal_x,
                hit.normal_y,
                hit.fraction,
                hit.source_shape,
                hit.target_shape
            )
        end
    end

    return result
end

return SpatialMover
