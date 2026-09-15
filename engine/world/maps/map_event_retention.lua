---@class MapEventRetention: MapEventRetentionFields
local MapEventRetention = {}
MapEventRetention.__index = MapEventRetention

--- Clears a reused list or membership index.
---@param values table Table owned by this retention index.
local function clear(values)
  for key in pairs(values) do values[key] = nil end
end

--- Includes the authored owner of one event participant.
---@param self MapEventRetention Retention index being refreshed.
---@param entity Entity? Event owner or activator.
local function include_owner(self, entity)
  if entity == nil then return end
  local owner = self.collection:get_owner(entity)
  if owner == nil then return end

  local map = owner.region
  if self.pending_by_id[map.id] ~= nil then return end
  self.pending_by_id[map.id] = map
  self.pending_maps[#self.pending_maps + 1] = map
end

--- Collects map ownership without inferring dependencies inside event commands.
---@param context table Context preserved by an unfinished runner.
---@param self MapEventRetention Retention index being refreshed.
local function collect_context(context, self)
  include_owner(self, context.entity)
  include_owner(self, context.activator)
end

--- Creates an empty retention index; refresh it after events have been queued.
---@param collection ResidentMapCollection Immutable ownership of original entities.
---@param scheduler table Event scheduler exposing visit_pending_contexts.
---@return MapEventRetention retention Maps required by unfinished event participants.
function MapEventRetention.new(collection, scheduler)
  assert(collection ~= nil and type(collection.get_owner) == "function",
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
--- Shared participants need no map retention because they have no authored owner.
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
---@return MapRegion[] maps Maps required by unfinished event participants.
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

return MapEventRetention
