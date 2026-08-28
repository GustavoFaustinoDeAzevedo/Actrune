local RenderLayer = {}
RenderLayer.__index = RenderLayer

-- Creates one ordered render layer with an optional view transformation.
function RenderLayer.new(options)
  options = options or {}

  assert(type(options.name) == "string" and options.name ~= "", "render layer requires a name")
  assert(type(options.draw) == "function", "render layer requires a draw callback")

  return setmetatable({
    name = options.name,
    order = options.order or 0,
    view = options.view,
    draw_callback = options.draw,
    enabled = options.enabled ~= false
  }, RenderLayer)
end

-- Returns the layer name.
function RenderLayer:get_name()
  return self.name
end

-- Returns the layer drawing order.
function RenderLayer:get_order()
  return self.order
end

-- Changes the view transformation applied to this layer.
function RenderLayer:set_view(view)
  self.view = view
end

-- Enables or disables this layer.
function RenderLayer:set_enabled(enabled)
  self.enabled = enabled == true
end

-- Draws the layer through its optional view transformation.
function RenderLayer:draw(context)
  if not self.enabled then return end

  if self.view ~= nil then
    assert(type(self.view.begin) == "function" and type(self.view.finish) == "function",
      "render layer view must expose begin and finish")
    self.view:begin(context)
  end

  self.draw_callback(context)

  if self.view ~= nil then self.view:finish(context) end
end

return RenderLayer
