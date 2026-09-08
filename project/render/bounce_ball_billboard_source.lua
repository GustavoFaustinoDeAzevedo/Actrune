local love = require("love")

local AnimationPlayer = require("engine.core.animation.animation_player")
local BillboardVisual = require("engine.render.billboard_visual")
local IndexedBillboardVisual = require("engine.render.indexed_billboard_visual")

local BounceBallBillboardSource = {}
BounceBallBillboardSource.__index = BounceBallBillboardSource

-- Creates one temporary animated billboard source for the bouncing-ball render test.
function BounceBallBillboardSource.new(options)
  options = options or {}

  assert(type(options.entity_id) == "string" and options.entity_id ~= "",
    "bounce ball billboard source requires a non-empty entity id")
  assert(options.entity ~= nil and type(options.entity.get_position) == "function",
    "bounce ball billboard source requires an entity exposing get_position")
  assert(options.animation_clip ~= nil,
    "bounce ball billboard source requires an animation clip")

  local self = setmetatable({}, BounceBallBillboardSource)

  -- These references connect the test visual to its world entity and animation timing.
  self.entity_id = options.entity_id
  self.entity = options.entity
  self.animation = AnimationPlayer.new(options.animation_clip)

  -- These procedural frames intentionally remain project-side because they are temporary test visuals.
  local frame_a = BillboardVisual.new({
    width = 20,
    height = 20,
    draw = function(width, height)
      love.graphics.setColor(1, 1, 1, 0.7)
      love.graphics.circle("fill", width * 0.5, height * 0.5, 20)
    end
  })

  local frame_b = BillboardVisual.new({
    width = 20,
    height = 20,
    draw = function(width, height)
      love.graphics.setColor(1, 1, 1, 0.8)
      love.graphics.circle("fill", width * 0.5, height * 0.5, 30)
    end
  })

  local frame_c = BillboardVisual.new({
    width = 20,
    height = 20,
    draw = function(width, height)
      love.graphics.setColor(1, 1, 1, 0.9)
      love.graphics.circle("fill", width * 0.5, height * 0.5, 20)
    end
  })

  -- The indexed visual selects a procedural frame using this source's independent playback state.
  local visual = IndexedBillboardVisual.new({
    visuals = {
      frame_a,
      frame_b,
      frame_c,
      frame_b
    },
    index_provider = function()
      return self.animation:get_frame_index()
    end
  })

  -- This entry remains stable while its providers read current runtime state when rendered.
  self.entry = {
    id = self.entity_id,
    position_provider = function()
      return self.entity:get_position()
    end,
    visual = visual
  }

  return self
end

-- Appends the bouncing-ball billboard to a destination entry collection.
function BounceBallBillboardSource:append_entries(entries)
  assert(type(entries) == "table",
    "bounce ball billboard source destination must be a table")

  entries[#entries + 1] = self.entry
end

-- Advances the temporary bouncing-ball visual animation.
function BounceBallBillboardSource:update(dt)
  self.animation:update(dt)
end

return BounceBallBillboardSource
