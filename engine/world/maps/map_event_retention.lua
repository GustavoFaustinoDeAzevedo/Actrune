---@class MapEventRetention: MapEventRetentionFields
local MapEventRetention = {}
MapEventRetention.__index = MapEventRetention

--- Clears a reused list or membership index.
---@param values table Table owned by this retention index.
local function clear(values)
  for key in pairs(values) do values[key] = nil end
end

--- Includes a resolved map once per refresh.
---@param self MapEventRetention Retention index being refreshed.
---@param map MapRegion Required region.
local function include_map(self, map)
  if self.pending_by_id[map.id] ~= nil then return end
  self.pending_by_id[map.id] = map
  self.pending_maps[#self.pending_maps + 1] = map
end

--- Includes the authored owner of one event participant.
---@param self MapEventRetention Retention index being refreshed.
---@param entity Entity? Event owner or activator.
local function include_owner(self, entity)
  if entity == nil then return end
  local owner = self.collection:get_owner(entity)
  if owner ~= nil then include_map(self, owner.region) end
end

--- Uses the page captured by this runner, even if another page is now available.
---@param context table Context preserved by the unfinished runner.
---@param self MapEventRetention Retention index being refreshed.
---@param runner table Original runner exposing its captured page.
local function collect_context(context, self, runner)
  include_owner(self, context.entity)
  include_owner(self, context.activator)

  for _, id in ipairs(runner.page.required_maps or {}) do
    local resident = self.collection:get_map(id)
    assert(resident ~= nil, "event requires unknown map: " .. id)
    include_map(self, resident.region)
  end
end

--- Creates an empty retention index; refresh it after events have been queued.
---@param collection ResidentMapCollection Immutable ownership of original entities.
---@param scheduler table Event scheduler exposing visit_pending_contexts.
---@return MapEventRetention retention Maps required by unfinished event executions.
function MapEventRetention.new(collection, scheduler)
  assert(collection ~= nil and type(collection.get_owner) == "function"
    and type(collection.get_map) == "function",
    "map event retention requires a resident map collection")
  assert(scheduler ~= nil and type(scheduler.visit_pending_contexts) == "function",
    "map event retention requires an event scheduler")

  return setmetatable({
    collection = collection,
    scheduler = scheduler,
    maps = {},
    maps_by_id = {},
    pending_maps = {},
    pending_by_id = {},
    revision = 0
  }, MapEventRetention)
end

--- Rebuilds requirements from unfinished runners, reusing all internal tables.
--- Membership changes advance the revision; runner order alone does not.
--- Shared participants add no owner map; explicit page requirements still apply.
---@return boolean changed Whether the required map membership changed.
function MapEventRetention:refresh()
  clear(self.pending_maps)
  clear(self.pending_by_id)
  self.scheduler:visit_pending_contexts(collect_context, self)

  local changed = #self.maps ~= #self.pending_maps
  if not changed then
    for _, map in ipairs(self.pending_maps) do
      if self.maps_by_id[map.id] == nil then
        changed = true; break
      end
    end
  end
  if not changed then return false end

  clear(self.maps)
  clear(self.maps_by_id)
  for index, map in ipairs(self.pending_maps) do
    self.maps[index] = map
    self.maps_by_id[map.id] = map
  end
  self.revision = self.revision + 1
  return true
end

--- Returns the live event requirements from the last refresh.
--- Treat the list as read-only; this same table is reused after changes.
---@return MapRegion[] maps Maps required by unfinished event executions.
function MapEventRetention:get_maps()
  return self.maps
end

--- Checks event retention independently of current-map and neighbor selection.
---@param id string Map identifier.
---@return boolean retained Whether an unfinished participant requires this map.
function MapEventRetention:contains(id)
  return self.maps_by_id[id] ~= nil
end

--- Returns a counter that changes only when required map membership changes.
---@return integer revision Zero before the first membership change.
function MapEventRetention:get_revision()
  return self.revision
end

--- Validates every loaded page against the layout selected by this runtime.
--- Runs once before simulation, including pages whose conditions are currently false.
---@param entities Entity[] Original loaded project entities.
---@param collection ResidentMapCollection? Content index, or nil without a layout.
function MapEventRetention.validate_entities(entities, collection)
  for _, entity in ipairs(entities) do
    for _, event in pairs(entity:get_events()) do
      for index, page in ipairs(event.pages or {}) do
        for _, id in ipairs(page.required_maps or {}) do
          assert(collection ~= nil and collection:get_map(id) ~= nil,
            string.format("entity '%s', event '%s', page %d requires unknown map '%s'",
              entity.id, event.id, index, id))
        end
      end
    end
  end
end

return MapEventRetention
