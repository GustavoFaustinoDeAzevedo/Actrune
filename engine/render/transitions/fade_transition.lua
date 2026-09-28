local love = require("love")

---@class FadeTransition: FadeTransitionFields
local FadeTransition = {}
FadeTransition.__index = FadeTransition

--- Creates independent cover/reveal timing; no simulation or camera dependencies.
---@param options? table Optional cover_duration and reveal_duration, in seconds.
---@return FadeTransition effect New effect owned by one execution.
function FadeTransition.new(options)
  options = options or {}
  local cover, reveal = options.cover_duration or 0.12, options.reveal_duration or 0.18
  for _, duration in ipairs({ cover, reveal }) do
    assert(type(duration) == "number" and duration >= 0 and duration < math.huge,
      "fade durations must be finite and non-negative")
  end
  return setmetatable({
    cover_duration = cover,
    reveal_duration = reveal,
    elapsed = 0,
    revealing = false,
    alpha = 0
  }, FadeTransition)
end

--- Requests destination application only after covering the screen.
---@param dt number Finite non-negative elapsed seconds, validated by TransitionRunner.
---@param applied boolean Whether destination application succeeded.
---@return TransitionStep step Next execution instruction.
function FadeTransition:update(dt, applied)
  if applied and not self.revealing then
    self.revealing, self.elapsed = true, 0
  end
  self.elapsed = self.elapsed + dt
  if not applied then
    self.alpha = self.cover_duration == 0 and 1 or math.min(self.elapsed / self.cover_duration, 1)
    return self.alpha == 1 and "apply" or "running"
  end
  self.alpha = self.reveal_duration == 0 and 0 or math.max(1 - self.elapsed / self.reveal_duration, 0)
  return self.alpha == 0 and "done" or "running"
end

--- Draws a screen-space overlay after the scene; always restores graphics state.
function FadeTransition:draw()
  if self.alpha == 0 then return end
  love.graphics.push("all")
  local ok, err = pcall(function()
    love.graphics.origin()
    love.graphics.setShader()
    love.graphics.setScissor()
    love.graphics.setStencilTest()
    love.graphics.setBlendMode("alpha", "alphamultiply")
    love.graphics.setColor(0, 0, 0, self.alpha)
    local width, height = love.graphics.getDimensions()
    love.graphics.rectangle("fill", 0, 0, width, height)
  end)
  love.graphics.pop()
  if not ok then error(err, 0) end
end

return FadeTransition
