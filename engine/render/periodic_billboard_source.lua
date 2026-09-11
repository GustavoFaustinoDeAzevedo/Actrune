---@class PeriodicBillboardSource: PeriodicBillboardSourceFields
local PeriodicBillboardSource = {}
PeriodicBillboardSource.__index = PeriodicBillboardSource

--- Encloses the rotated orthographic viewport with world-space padding.
---@param camera table Camera exposing position, viewport, rotation and zoom.
---@param padding number Extra margin in world units.
---@return number min_x Left world bound.
---@return number min_y Upper world bound.
---@return number max_x Right world bound.
---@return number max_y Lower world bound.
function PeriodicBillboardSource.get_view_bounds(camera, padding)
  local x, y = camera:get_position()
  local _, _, width, height = camera:get_viewport()
  local zoom, rotation = camera:get_zoom(), camera:get_rotation()
  local cosine, sine = math.abs(math.cos(rotation)), math.abs(math.sin(rotation))
  local half_x = (width * cosine + height * sine) * 0.5 / zoom + padding
  local half_y = (width * sine + height * cosine) * 0.5 / zoom + padding

  return x - half_x, y - half_y, x + half_x, y + half_y
end

--- Creates repeated entries using an orthographic viewport or supplied world bounds.
--- Padding must cover visual extent from the anchor, including scale and local transforms.
---@param source table Original source exposing get_entries.
---@param topology WorldTopology Map repetition configuration.
---@param camera table Camera supplying viewport and elevation displacement rotation.
---@param options PeriodicBillboardSourceOptions Coverage and elevation settings.
---@return PeriodicBillboardSource source Reusable visual adapter.
function PeriodicBillboardSource.new(source, topology, camera, options)
  assert(source ~= nil and type(source.get_entries) == "function",
    "periodic billboards require a source exposing get_entries")
  assert(topology ~= nil and type(topology.get_bounds) == "function",
    "periodic billboards require world topology")
  assert(type(options) == "table", "periodic billboards require options")
  assert(type(options.padding) == "number" and options.padding >= 0 and options.padding < math.huge,
    "periodic billboard padding must be finite and non-negative")
  assert(type(options.elevation_scale) == "number"
    and options.elevation_scale >= 0 and options.elevation_scale < math.huge,
    "periodic billboard elevation scale must be finite and non-negative")
  assert(options.bounds_provider == nil or type(options.bounds_provider) == "function",
    "periodic billboard bounds provider must be a function")

  for _, name in ipairs({ "get_position", "get_viewport", "get_rotation", "get_zoom" }) do
    assert(camera ~= nil and type(camera[name]) == "function",
      "periodic billboard camera must expose " .. name)
  end

  return setmetatable({
    source = source,
    topology = topology,
    camera = camera,
    padding = options.padding,
    elevation_scale = options.elevation_scale,
    bounds_provider = options.bounds_provider,
    entries = {},
    copies = {}
  }, PeriodicBillboardSource)
end

-- Selects periodic anchors intersecting one visible axis.
local function axis_range(position, minimum, maximum, period)
  if period ~= nil then
    return math.ceil((minimum - position) / period), math.floor((maximum - position) / period)
  end

  if position >= minimum and position <= maximum then return 0, 0 end
  return 1, 0
end

--- Collects visible repetitions for one global projection and depth sort.
--- Samples position and Z once per original entry on each call.
--- Preserves original entries and reuses output tables; consume before the next call.
---@return table[] entries Repeated visual entries for the current draw.
function PeriodicBillboardSource:get_entries()
  local originals = self.source:get_entries()
  local topology = self.topology
  local period_x = topology.loop_x and topology.width or nil
  local period_y = topology.loop_y and topology.height or nil
  local min_x, min_y, max_x, max_y

  if self.bounds_provider ~= nil then
    min_x, min_y, max_x, max_y = self.bounds_provider(self.padding)

    assert(type(min_x) == "number" and type(min_y) == "number"
      and type(max_x) == "number" and type(max_y) == "number"
      and min_x > -math.huge and min_y > -math.huge
      and max_x < math.huge and max_y < math.huge
      and min_x <= max_x and min_y <= max_y,
      "periodic billboard bounds must be finite and ordered")
  else
    min_x, min_y, max_x, max_y = self.get_view_bounds(self.camera, self.padding)
  end
  
  local rotation = self.camera:get_rotation()
  local sine, cosine = math.sin(rotation), math.cos(rotation)
  local count = 0

  for _, entry in ipairs(originals) do
    if entry.enabled ~= false then
      local x, y = entry.x, entry.y
      if entry.position_provider ~= nil then x, y = entry.position_provider() end

      local elevation = entry.elevation or 0
      if entry.elevation_provider ~= nil then elevation = entry.elevation_provider() end

      assert(type(x) == "number" and x > -math.huge and x < math.huge
        and type(y) == "number" and y > -math.huge and y < math.huge,
        "periodic billboard positions must be finite")
      assert(type(elevation) == "number" and elevation > -math.huge and elevation < math.huge,
        "periodic billboard elevation must be finite")

      local offset = elevation * self.elevation_scale
      local first_x, last_x = axis_range(x + sine * offset, min_x, max_x, period_x)
      local first_y, last_y = axis_range(y - cosine * offset, min_y, max_y, period_y)

      for image_y = first_y, last_y do
        for image_x = first_x, last_x do
          count = count + 1
          local copy = self.copies[count] or {}
          self.copies[count] = copy

          for key in pairs(copy) do copy[key] = nil end
          for key, value in pairs(entry) do copy[key] = value end

          copy.x = x + image_x * (period_x or 0)
          copy.y = y + image_y * (period_y or 0)
          copy.elevation = elevation
          copy.position_provider, copy.elevation_provider = nil, nil
          copy.source_entry = entry
          copy.repeat_x, copy.repeat_y = image_x, image_y
          self.entries[count] = copy
        end
      end
    end
  end

  for index = #self.entries, count + 1, -1 do
    local copy = self.entries[index]
    for key in pairs(copy) do copy[key] = nil end
    self.entries[index] = nil
  end

  return self.entries
end

return PeriodicBillboardSource
