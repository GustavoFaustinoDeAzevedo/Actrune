local love = require("love")

local BillboardVisual = require("engine.render.billboard_visual")

local ProjectedDebugBillboardSource = {}
ProjectedDebugBillboardSource.__index = ProjectedDebugBillboardSource

-- Creates the temporary projected billboard visuals used to inspect the current test scene.
function ProjectedDebugBillboardSource.new(options)
  options = options or {}

  assert(options.floor ~= nil and type(options.floor.get_position) == "function",
    "projected debug billboard source requires a floor entity exposing get_position")
  assert(options.door ~= nil and type(options.door.get_position) == "function",
    "projected debug billboard source requires a door entity exposing get_position")

  local self = setmetatable({}, ProjectedDebugBillboardSource)

  -- These entities provide the live world positions used by the debug billboard providers.
  self.floor = options.floor
  self.door = options.door

  -- These entries remain stable while their position providers read current entity state.
  self.entries = {
    {
      id = "floor_marker",
      position_provider = function()
        return self.floor:get_position()
      end,
      visual = BillboardVisual.new({
        width = 16,
        height = 48,
        draw = function(width, height)
          love.graphics.setColor(1, 1, 1, 1)
          love.graphics.line(width * 0.5, height, width * 0.5, 0)
          love.graphics.circle("line", width * 0.5, 0, width * 0.5)
        end
      })
    },
    {
      id = "door",
      position_provider = function()
        return self.door:get_position()
      end,
      visual = BillboardVisual.new({
        width = 500,
        height = 800,
        draw = function(width, height)
          love.graphics.setColor(0, 0, 1, 1)
          love.graphics.rectangle("fill", 0, 0, width, height)
          love.graphics.setColor(1, 1, 1, 1)
          love.graphics.circle("line", width - 30, height * 0.5, 20)
        end
      })
    }
  }

  return self
end

--- Appends only debug visuals whose original entities remain active.
---@param entries table[] Destination billboard list.
function ProjectedDebugBillboardSource:append_entries(entries)
  assert(type(entries) == "table",
    "projected debug billboard source destination must be a table")

  if self.floor:is_active() then entries[#entries + 1] = self.entries[1] end
  if self.door:is_active() then entries[#entries + 1] = self.entries[2] end
end

return ProjectedDebugBillboardSource
