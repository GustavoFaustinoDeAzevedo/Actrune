local love = require "love"

local ActruneProjectLoader = require("engine.core.project.actrune_project_loader")
local ProjectRuntime = require("engine.core.project.project_runtime")

local project_definition = require("project.project_definition")

-- This factory resolves project-specific renderer dependencies before creating the renderer.
local TestSceneRendererFactory = require("project.test_scene_renderer_factory")

local ProjectRuntimeConfiguration = require("project.runtime_configuration")

-- These resource types describe render data owned by the current project.
local ProjectRenderResourceTypes = require("project.render.resource_types")

local game
local messages = {}

-- Controls optional diagnostics owned by the development entry point.
local performance_enabled = true

local performance = {
    elapsed = 0,
    update_total = 0,
    update_count = 0,
    draw_total = 0,
    draw_count = 0,
    max_delta = 0,
    graphics = {},
    text = ""
}

-- Refreshes diagnostic text periodically while reusing the graphics statistics table.
local function refresh_performance_text()
    if performance.elapsed < 0.5 then return end

    local stats = love.graphics.getStats(performance.graphics)
    local update_ms = performance.update_total * 1000 / math.max(1, performance.update_count)
    local draw_ms = performance.draw_total * 1000 / math.max(1, performance.draw_count)

    performance.text = string.format(
        "Performance\n"
        .. "FPS: %d | Frame avg: %.2f ms\n"
        .. "Frame max (window): %.2f ms\n"
        .. "Update avg: %.3f ms\n"
        .. "Draw call avg: %.3f ms\n"
        .. "Draw calls (sample): %d\n"
        .. "Canvas switches (sample): %d\n"
        .. "Lua memory: %.2f MiB\n"
        .. "Texture memory (est.): %.2f MiB",
        love.timer.getFPS(),
        love.timer.getAverageDelta() * 1000,
        performance.max_delta * 1000,
        update_ms,
        draw_ms,
        stats.drawcalls,
        stats.canvasswitches,
        collectgarbage("count") / 1024,
        stats.texturememory / (1024 * 1024)
    )

    performance.elapsed = 0
    performance.update_total = 0
    performance.update_count = 0
    performance.draw_total = 0
    performance.draw_count = 0
    performance.max_delta = 0
end

-- Draws diagnostics after the measured runtime rendering has finished.
local function draw_performance()
    if performance.text == "" then return end

    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.setShader()
    love.graphics.setScissor()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 12, 12, 250, 180)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(performance.text, 20, 20)
    love.graphics.pop()
end

-- Adds a message to the current test output.
local function add_message(message)
    table.insert(messages, message)
end

-- Adds the test event start message.
local function on_test_event_started()
    add_message("Evento iniciado.")
end

-- Adds the test event completion message.
local function on_test_event_finished()
    add_message("Evento finalizado.")
end

-- Loads and validates the current project definition.
local function load_project()
    local project_loader = ActruneProjectLoader.new()

    -- This register groups extensions supplied by the current project under one provider.
    local project_register =
        project_loader:create_register("project")

    -- Runtime and rendering extensions use the same project-owned configuration boundary.
    ProjectRuntimeConfiguration.register(project_register)
    ProjectRenderResourceTypes.register(project_register)

    local configuration = project_loader:get_configuration()

    print(configuration:get_resource_provider("physical_material"))
    print(configuration:get_resource_provider("grid_metrics"))
    print(configuration:get_resource_provider("input_map"))
    print(configuration:get_resource_provider("control_profile"))

    project_loader:register_event_action("test_event_started", on_test_event_started)
    project_loader:register_event_action("test_event_finished", on_test_event_finished)

    return project_loader:load(project_definition)
end

-- Creates the current Actrune test project runtime.
function love.load()
    game = ProjectRuntime.new({
        project = load_project(),

        -- The project-specific factory injects the billboard sources required by the renderer.
        renderer_factory = TestSceneRendererFactory.create,
    })
end

-- Advances the runtime and optionally measures its elapsed execution time.
function love.update(dt)
    if not performance_enabled then
        game:update(dt)
        return
    end

    local started = love.timer.getTime()
    game:update(dt)

    performance.update_total =
        performance.update_total + love.timer.getTime() - started
    performance.update_count = performance.update_count + 1
    performance.elapsed = performance.elapsed + dt
    performance.max_delta = math.max(performance.max_delta, dt)
end

-- Measures runtime drawing before collecting and displaying diagnostics.
function love.draw()
    if not performance_enabled then
        game:draw()
        return
    end

    local started = love.timer.getTime()
    game:draw()

    performance.draw_total =
        performance.draw_total + love.timer.getTime() - started
    performance.draw_count = performance.draw_count + 1

    refresh_performance_text()
    draw_performance()
end

-- Forwards keyboard press events to the project runtime.
function love.keypressed(key)
    game:key_pressed(key)
end

-- Forwards keyboard release events to the project runtime.
function love.keyreleased(key)
    game:key_released(key)
end
