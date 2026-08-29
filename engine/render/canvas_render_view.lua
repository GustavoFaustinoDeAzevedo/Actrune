local love = require "love"

local CanvasRenderView = {}
CanvasRenderView.__index = CanvasRenderView

-- Creates an offscreen render view that captures content before presenting it.
function CanvasRenderView.new(options)
  options = options or {}

  local self = setmetatable({}, CanvasRenderView)
  self.width = options.width
  self.height = options.height
  self.presenter = options.presenter
  self.canvas = nil
  self.previous_canvases = {}

  assert(self.width == nil or type(self.width) == "number" and self.width > 0,
    "canvas render view width must be nil or greater than zero")
  assert(self.height == nil or type(self.height) == "number" and self.height > 0,
    "canvas render view height must be nil or greater than zero")
  assert(
    self.presenter == nil or type(self.presenter) == "function" or
    type(self.presenter) == "table" and type(self.presenter.present) == "function",
    "canvas render view presenter must be nil, a function, or expose present"
  )

  return self
end

-- Returns the effective offscreen dimensions.
function CanvasRenderView:_get_dimensions()
  local window_width, window_height = love.graphics.getDimensions()
  return self.width or window_width, self.height or window_height
end

-- Ensures that the backing canvas matches the effective dimensions.
function CanvasRenderView:_ensure_canvas()
  local width, height = self:_get_dimensions()

  if self.canvas ~= nil and self.canvas:getWidth() == width and self.canvas:getHeight() == height then return end

  self.canvas = love.graphics.newCanvas(width, height)
end

-- Returns the current backing canvas.
function CanvasRenderView:get_canvas()
  self:_ensure_canvas()
  return self.canvas
end

-- Begins capturing subsequent drawing into the offscreen canvas.
function CanvasRenderView:begin()
  self:_ensure_canvas()

  table.insert(self.previous_canvases, {
    canvas = love.graphics.getCanvas()
  })

  love.graphics.setCanvas(self.canvas)
  love.graphics.clear(0, 0, 0, 0)
end

-- Presents the captured canvas back to the previous render target.
function CanvasRenderView:finish(context)
  assert(#self.previous_canvases > 0, "canvas render view finish called without matching begin")

  local previous = table.remove(self.previous_canvases)
  love.graphics.setCanvas(previous.canvas)

  love.graphics.push("all")
  love.graphics.origin()

  if type(self.presenter) == "function" then
    self.presenter(self.canvas, context)
  elseif self.presenter ~= nil then
    self.presenter:present(self.canvas, context)
  else
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.canvas, 0, 0)
  end

  love.graphics.pop()
end

return CanvasRenderView
