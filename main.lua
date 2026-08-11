local Actrune = require("engine.core.actrune")

local eventFolder = "engine/events/"
local Event = require(eventFolder .. "event")
local EventPage = require(eventFolder .. "event_page")
local EventContext = require(eventFolder .. "event_context")
local EventTrigger = require(eventFolder .. "event_trigger")
local AreaTrigger = require(eventFolder .. "triggers.area_trigger")

local commandFolder = "engine/events/commands/"
local CallCommand = require(commandFolder .. "call_command")
local WaitCommand = require(commandFolder .. "wait_command")

local Entity = require("engine.world.entity")
local PolygonShape = require("engine.world.spatial.polygon_shape")

local event_entity
local player_entity
local test_entity
local runtime
local messages = {}


-- Adds a message to the test output.
local function add_message(message)
    table.insert(messages, message)
end

-- Creates the Actrune runtime and starts the test event.
function love.load()
    runtime = Actrune.new() 

    event_entity = Entity.new({
        id = "door",
        x = 200,
        y = 150,

        shapes = {
            interaction = PolygonShape.new({
                points = {
                    { x = -50, y = -40 },
                    { x = 50, y = -40 },
                    { x = 50, y = 40 },
                    { x = -50, y = 40 }
                }
            })
        }
    })

    player_entity = Entity.new({
        id = "player",
        x = 260,
        y = 150,

        shapes = {
            collision = PolygonShape.new({
                points = {
                    { x = -15, y = -15 },
                    { x = 15, y = -15 },
                    { x = 15, y = 15 },
                    { x = -15, y = 15 }
                }
            })
        }
    })

    runtime:add_entity(event_entity)
    runtime:add_entity(player_entity)

    local player_shape = player_entity:get_shape("collision")
    local player_points =
        player_shape:get_world_points(player_entity.transform)

    print("Player X min:", player_points[1])
    print("Player X max:", player_points[3])
    
    local player_x, player_y =
    player_entity:get_position()

    runtime:trigger_events_at_point(
        player_x,
        player_y,
        "interaction",
        "interact",
        player_entity
    )

    local entities =
    runtime.world:query_point(
        200,
        150,
        "interaction"
    )

    for _, entity in ipairs(entities) do
        print("Found entity: " .. entity.id)
    end
    
    local event = Event.new({
        id = "test_event",

        pages = {
            EventPage.new({
                trigger = AreaTrigger.new({
                    type = "interact",
                    shape = "interaction",
                    activator_shape = "collision"
                }),

                commands = {
                    CallCommand.new(function()
                        add_message("Evento iniciado.")
                    end),

                    WaitCommand.new(2),

                    CallCommand.new(function()
                        add_message("Evento finalizado.")
                    end)
                }
            })
        }
    })

    local context = EventContext.new({
        source = event,
        entity = event_entity,
        activator = player_entity,
        world = runtime.world
    })
    
    runtime:trigger_event(
        event,
        "interact",
        context
    )

    -- test_entity = Entity.new({
    --     id = "test_entity",
    --     x = 120,
    --     y = 80,

    --     shape = PolygonShape.new({
    --         points = {
    --             { x = -30, y = -20 },
    --             { x = 30, y = -20 },
    --             { x = 40, y = 20 },
    --             { x = 0, y = 40 },
    --             { x = -40, y = 20 }
    --         }
    --     })
    -- })
    print(runtime:get_entity("player").id)
    test_entity = Entity.new({
        id = "test_entity",
        x = 200,
        y = 150,
        rotation = math.rad(30),

        shapes = {
            interaction = PolygonShape.new({
                points = {
                    { x = -30, y = -20 },
                    { x = 30, y = -20 },
                    { x = 40, y = 20 },
                    { x = 0, y = 40 },
                    { x = -40, y = 20 }
                }
            })
        }
    })
    
end

-- Updates the Actrune runtime every frame.
function love.update(dt)
    runtime:update(dt)
end

-- Draws the current event execution state for testing.
function love.draw()

    love.graphics.print(
        table.concat(messages, "\n"),
        20,
        20
    )

    love.graphics.print(
        "Active events: " .. runtime:get_active_event_count(),
        20,
        100
    ) 

    local shape = test_entity:get_shape("interaction")

    if shape then
        local world_points =
            shape:get_world_points(test_entity.transform)

        love.graphics.polygon(
            "line",
            world_points
        )

        local mouse_x, mouse_y = love.mouse.getPosition()

        if shape:contains_point(
            mouse_x,
            mouse_y,
            test_entity.transform
        ) then
            love.graphics.print(
                "Mouse inside shape",
                20,
                140
            )
        else
            love.graphics.print(
                "" ,
                20,
                140
            )
        end
    end
end