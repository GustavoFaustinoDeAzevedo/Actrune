local AnimatedEntityVisualRuntimeSystem = require("engine.render.animated_entity_visual_runtime_system")
local StaticEntityVisualRuntimeSystem = require("engine.render.static_entity_visual_runtime_system")
local ResidentMapCollection = require("engine.world.maps.resident_map_collection")
local MapLocationTracker = require("engine.world.maps.map_location_tracker")
local MapEventDispatcher = require("engine.world.maps.map_event_dispatcher")
local MapResidencySelection = require("engine.world.maps.map_residency_selection")

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
      --- Resolves content from the selected layout, falling back to the main layout.
      ---@param self table Initialization adapter.
      ---@param context table Loaded project and its runtime.
      initialize = function(self, context)
        local bindings = context.project.resources.map_location_binding
        ---@type MapLocationBinding?
        local binding = bindings and bindings:get("main")
        local layouts = context.project.resources.map_layout
        local layout = binding and binding.layout or layouts and layouts:get("main")

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
    ---@type MapResidencySelection?
    local selection

    return {
      --- Resolves the configured entity and initializes location and desired residency.
      ---@param self table Map observation adapter.
      ---@param context table Loaded project and its runtime.
      initialize = function(self, context)
        local bindings = context.project.resources.map_location_binding
        ---@type MapLocationBinding?
        local binding = bindings and bindings:get("main")
        if binding == nil then return end

        local entity = context.project.entities_by_id[binding.entity_id]
        assert(entity ~= nil, "map location references missing entity: " .. binding.entity_id)
        tracker = MapLocationTracker.new(binding.layout, entity)
        selection = MapResidencySelection.new(binding.layout)
        selection:set_current_map(tracker:get_map())
      end,

      --- Updates desired residency before queuing events and notifying the project.
      ---@param self table Map observation adapter.
      ---@param dt number Elapsed simulation time in seconds.
      ---@param context table Loaded project and its runtime.
      after_update = function(self, dt, context)
        if tracker == nil or selection == nil then return end

        local changed, previous, current = tracker:refresh()
        if not changed then return end
        selection:set_current_map(current)

        local maps = context.project_runtime:get_system("resident_maps"):get_collection()
        MapEventDispatcher.dispatch(context.runtime, maps, tracker.entity, previous, current)

        if on_map_changed ~= nil then
          on_map_changed(tracker.entity, previous, current)
        end
      end,

      --- Returns the observer created from the main map location binding.
      ---@param self table Map observation adapter.
      ---@return MapLocationTracker|nil tracker Observer, or nil without a binding.
      get_tracker = function(self)
        return tracker
      end,

      --- Returns desired residency without changing the actual resident content.
      ---@param self table Map observation adapter.
      ---@return MapResidencySelection|nil selection Desired maps, or nil without a binding.
      get_selection = function(self)
        return selection
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
