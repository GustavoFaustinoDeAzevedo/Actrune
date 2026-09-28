local AnimatedEntityVisualRuntimeSystem = require("engine.render.animated_entity_visual_runtime_system")
local StaticEntityVisualRuntimeSystem = require("engine.render.static_entity_visual_runtime_system")
local ResidentMapCollection = require("engine.world.maps.resident_map_collection")
local MapLocationTracker = require("engine.world.maps.map_location_tracker")
local MapEventDispatcher = require("engine.world.maps.map_event_dispatcher")
local MapResidencySelection = require("engine.world.maps.map_residency_selection")
local MapEventRetention = require("engine.world.maps.map_event_retention")

local RuntimeConfiguration = {}

--- Registers the runtime systems selected by this project.
---@param register table Project configuration exposing register_runtime_system.
---@param on_map_changed? MapLocationChanged Optional observer of sampled location changes.
---@param on_event_maps_changed? fun(retention: MapEventRetention) Observer of event requirement changes.
function RuntimeConfiguration.register(register, on_map_changed, on_event_maps_changed)
  assert(register ~= nil and type(register.register_runtime_system) == "function",
    "project runtime configuration requires a project configuration register")
  assert(on_map_changed == nil or type(on_map_changed) == "function",
    "map location callback must be a function")
  assert(on_event_maps_changed == nil or type(on_event_maps_changed) == "function",
    "event map callback must be a function")

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

  register:register_runtime_system("map_event_retention", function()
    ---@type MapEventRetention?
    local retention

    return {
      --- Validates declared dependencies against the selected resident content.
      ---@param self table Event requirement adapter.
      ---@param context table Loaded project and its runtime.
      initialize = function(self, context)
        local maps = context.project_runtime:get_system("resident_maps"):get_collection()
        MapEventRetention.validate_entities(context.project.entities, maps)
        if maps ~= nil then
          retention = MapEventRetention.new(maps, context.runtime.event_scheduler)
        end
      end,

      --- Includes events queued between frames before map activity is applied.
      ---@param self table Event requirement adapter.
      ---@param dt number Elapsed simulation time in seconds.
      ---@param context table Loaded project and its runtime.
      update = function(self, dt, context)
        self:after_update(dt, context)
      end,

      --- Refreshes requirements queued by systems before commands execute.
      ---@param self table Event requirement adapter.
      ---@param dt number Elapsed simulation time in seconds.
      ---@param context table Loaded project and its runtime.
      before_events = function(self, dt, context)
        self:after_update(dt, context)
      end,

      --- Refreshes requirements after map signals and event execution.
      ---@param self table Event requirement adapter.
      ---@param dt number Elapsed simulation time in seconds.
      ---@param context table Loaded project and its runtime.
      after_update = function(self, dt, context)
        if retention ~= nil and retention:refresh() and on_event_maps_changed ~= nil then
          on_event_maps_changed(retention)
        end
      end,

      --- Returns the existing event requirement index.
      ---@param self table Event requirement adapter.
      ---@return MapEventRetention? retention Index, or nil without a map layout.
      get_retention = function(self)
        return retention
      end
    }
  end, 75)

  register:register_runtime_system("map_activity", function()
    local selection, retention, probe
    local records, observers, required, states = {}, {}, {}, {}
    local active_count = 0
    local held = {}

    --- Includes a spatial actor's current map and its direct neighbors.
    local function include_map(map)
      if map == nil then return end
      required[map.id] = true
      for _, neighbor in ipairs(selection.layout:get_neighbors(map.id)) do
        required[neighbor.id] = true
      end
    end

    --- Applies the union of location, event and shared spatial actor requirements.
    local function refresh()
      if selection == nil then return end
      for id in pairs(required) do required[id] = nil end
      for _, map in ipairs(selection:get_maps()) do required[map.id] = true end
      for _, map in ipairs(retention:get_maps()) do required[map.id] = true end
      for id in pairs(held) do include_map(selection.layout:get_map(id)) end

      for _, observer in ipairs(observers) do
        if observer.entity:is_active() then
          observer:refresh()
          include_map(observer:get_map())
        end
      end

      active_count = 0
      for _, resident in ipairs(records) do
        local id = resident.region.id
        local active = required[id] == true
        if active then active_count = active_count + 1 end
        if states[id] ~= active then
          states[id] = active
          for _, entity in ipairs(resident.entities) do entity:set_active(active) end
        end
      end
    end

    return {
      --- Resolves existing instances and applies initial activity before simulation setup.
      ---@param self table Map activity adapter.
      ---@param context table Loaded project and its runtime.
      initialize = function(self, context)
        local location = context.project_runtime:get_system("player_map_location")
        local maps = context.project_runtime:get_system("resident_maps"):get_collection()
        selection = location:get_selection()
        if selection == nil or maps == nil then return end
        retention = context.project_runtime:get_system("map_event_retention"):get_retention()
        local tracker = location:get_tracker()
        assert(maps:get_owner(tracker.entity) == nil,
          "map activity requires the tracked traveller to be a shared entity")
        probe = MapLocationTracker.new(selection.layout, tracker.entity)

        for _, map in ipairs(selection.layout.ordered_maps) do
          records[#records + 1] = maps:get_map(map.id)
        end
        for _, entity in ipairs(maps:get_shared_entities()) do
          if next(entity.shapes) ~= nil then
            observers[#observers + 1] = MapLocationTracker.new(selection.layout, entity)
          end
        end
        retention:refresh()
        refresh()
      end,

      --- Handles externally changed positions before controls, grid and physics.
      ---@param self table Map activity adapter.
      ---@param dt number Elapsed simulation time in seconds.
      ---@param context table Loaded project and its runtime.
      update = function(self, dt, context)
        if probe == nil then return end
        probe:refresh()
        selection:set_current_map(probe:get_map())
        refresh()
      end,

      --- Activates declared dependencies before their event commands execute.
      ---@param self table Map activity adapter.
      ---@param dt number Elapsed simulation time in seconds.
      ---@param context table Loaded project and its runtime.
      before_events = function(self, dt, context)
        refresh()
      end,

      --- Applies final location and event requirements before rendering.
      ---@param self table Map activity adapter.
      ---@param dt number Elapsed simulation time in seconds.
      ---@param context table Loaded project and its runtime.
      after_update = function(self, dt, context)
        refresh()
      end,

      --- Keeps a map and its neighbors active until this caller releases them.
      ---@param self table Map activity adapter.
      ---@param id string Known map identifier.
      ---@return fun() release Idempotent release of this requirement.
      retain = function(self, id)
        assert(selection ~= nil and selection.layout:get_map(id) ~= nil,
          "cannot retain unknown map: " .. tostring(id))
        held[id] = (held[id] or 0) + 1
        refresh()
        local released = false
        return function()
          if released then return end
          released = true
          held[id] = held[id] > 1 and held[id] - 1 or nil
          refresh()
        end
      end,

      --- Returns applied activity; nil means an unknown map or no location binding.
      ---@param self table Map activity adapter.
      ---@param id string Map identifier.
      ---@return boolean? active Applied map state.
      is_map_active = function(self, id)
        return states[id]
      end,

      --- Returns the number of active maps managed by this adapter.
      ---@param self table Map activity adapter.
      ---@return integer count Active map count, or zero without a location binding.
      get_active_count = function(self)
        return active_count
      end
    }
  end, 80)

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
