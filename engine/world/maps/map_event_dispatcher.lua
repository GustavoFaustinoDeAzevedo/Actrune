local EventContext = require("engine.events.event_context")

local MapEventDispatcher = {}

--- Queues matching events on the original entities owned by one resident map.
--- Each runner receives independent variables containing the sampled map identifiers.
---@param runtime table Actrune runtime exposing trigger_event.
---@param resident ResidentMap? Authored content receiving the signal.
---@param activator Entity Original travelling entity.
---@param action string Named event signal.
---@param previous MapRegion? Region left by the traveller.
---@param current MapRegion? Region entered by the traveller.
---@return integer count Number of runners accepted by the runtime.
local function queue_events(runtime, resident, activator, action, previous, current)
  if resident == nil then return 0 end

  local count = 0
  for _, entity in ipairs(resident.entities) do
    for _, event in pairs(entity:get_events()) do
      local context = EventContext.new({
        source = event,
        entity = entity,
        activator = activator,
        world = runtime.world,
        variables = {
          map_id = resident.region.id,
          previous_map_id = previous and previous.id,
          current_map_id = current and current.id
        }
      })

      if runtime:trigger_event(event, action, context) ~= nil then count = count + 1 end
    end
  end
  return count
end

--- Queues map_exit and map_enter signals for one observed location change.
--- Scheduling preserves existing single/parallel modes and active event runners.
--- Exit and entry events are independent; their execution order belongs to the scheduler.
---@param runtime table Actrune runtime exposing trigger_event.
---@param maps ResidentMapCollection Content belonging to the tracker's layout.
---@param activator Entity Original travelling entity.
---@param previous MapRegion? Previously observed region.
---@param current MapRegion? Newly observed region.
---@return integer count Number of runners queued for this change.
function MapEventDispatcher.dispatch(runtime, maps, activator, previous, current)
  assert(runtime ~= nil and type(runtime.trigger_event) == "function",
    "map events require an event runtime")
  assert(maps ~= nil and type(maps.get_map) == "function",
    "map events require resident map content")
  assert(activator ~= nil, "map events require an activator")
  if previous == current then return 0 end

  local from = previous and maps:get_map(previous.id)
  local to = current and maps:get_map(current.id)
  assert(previous == nil or (from ~= nil and from.region == previous),
    "previous map does not belong to resident content")
  assert(current == nil or (to ~= nil and to.region == current),
    "current map does not belong to resident content")

  local count = queue_events(runtime, from, activator, "map_exit", previous, current)
  return count + queue_events(runtime, to, activator, "map_enter", previous, current)
end

return MapEventDispatcher
