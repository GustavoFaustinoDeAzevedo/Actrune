local AnimatedEntityVisualRuntimeSystem = require("engine.render.animated_entity_visual_runtime_system")
local StaticEntityVisualRuntimeSystem = require("engine.render.static_entity_visual_runtime_system")
local ResidentMapCollection = require("engine.world.maps.resident_map_collection")
local MapLocationTracker = require("engine.world.maps.map_location_tracker")

local RuntimeConfiguration = {}

--- Registers the runtime systems selected by this project.
---@param register table Project configuration exposing register_runtime_system.
---@param on_map_changed? MapLocationChanged Optional observer, called once per sampled change.
function RuntimeConfiguration.register(register, on_map_changed)
  assert(register ~= nil and type(register.register_runtime_system) == "function",
    "project runtime configuration requires a project configuration register")
  assert(on_map_changed == nil or type(on_map_changed) == "function",
    "map location callback must be a function")

  register:register_runtime_system("world_topology", function()
    return {
      --- Assigns the main map topology before other runtime systems initialize.
      ---@param self table Stateless initialization adapter.
      ---@param context table Loaded project and its Actrune runtime.
      initialize = function(self, context)
        local registry = context.project.resources.world_topology
        local topology = registry and registry:get("main")
        context.runtime.world:set_topology(topology)
      end
    }
  end, 50)

  register:register_runtime_system("resident_maps", function()
    ---@type ResidentMapCollection?
    local collection

    return {
      --- Resolves resident map content after project entities have been created.
      ---@param self table Initialization adapter.
      ---@param context table Loaded project and its runtime.
      initialize = function(self, context)
        local registry = context.project.resources.map_layout
        local layout = registry and registry:get("main")
        if layout ~= nil then
          collection = ResidentMapCollection.new(layout, context.project.entities)
        end
      end,

      --- Returns the resident content index when a main map layout exists.
      ---@param self table Initialization adapter.
      ---@return ResidentMapCollection|nil collection Resolved map content.
      get_collection = function(self)
        return collection
      end
    }
  end, 60)

  register:register_runtime_system("player_map_location", function()
    ---@type MapLocationTracker?
    local tracker

    return {
      --- Captures the player's initial map without emitting a transition.
      ---@param self table Location observer adapter.
      ---@param context table Loaded project and its runtime.
      initialize = function(self, context)
        local registry = context.project.resources.map_layout
        local layout = registry and registry:get("main")
        if layout == nil then return end

        local player = context.project.entities_by_id.player
        assert(player ~= nil, "player map location requires the player entity")
        tracker = MapLocationTracker.new(layout, player)
      end,

      --- Reports the final sampled location after movement and scheduled events.
      ---@param self table Location observer adapter.
      ---@param dt number Elapsed simulation time in seconds.
      ---@param context table Loaded project and its runtime.
      after_update = function(self, dt, context)
        if tracker == nil then return end

        local changed, previous, current = tracker:refresh()
        if changed and on_map_changed ~= nil then
          on_map_changed(tracker.entity, previous, current)
        end
      end,

      --- Returns the observer when this project has a main map layout.
      ---@param self table Location observer adapter.
      ---@return MapLocationTracker|nil tracker Player location observer.
      get_tracker = function(self)
        return tracker
      end
    }
  end, 70)

  register:register_runtime_system("animated_entity_visuals", function()
    return AnimatedEntityVisualRuntimeSystem.new({
      configuration_name = "projected_character_visuals"
    })
  end, 400)

  register:register_runtime_system("static_entity_visuals", function()
    return StaticEntityVisualRuntimeSystem.new({
      configuration_name = "projected_static_visuals"
    })
  end, 410)
end

return RuntimeConfiguration
