local RenderLayerStack = require("engine.render.render_layer_stack")

local RenderLayerGroup = {}
RenderLayerGroup.__index = RenderLayerGroup

-- Creates an ordered group of render layers with an optional shared view.
function RenderLayerGroup.new(options)
  options = options or {}

  assert(type(options.name) == "string" and options.name ~= "", "render layer group requires a name")

  return setmetatable({
    name = options.name,
    order = options.order or 0,
    view = options.view,
    enabled = options.enabled ~= false,
    layers = RenderLayerStack.new()
  }, RenderLayerGroup)
end

-- Returns the group name.
function RenderLayerGroup:get_name()
  return self.name
end

-- Returns the group drawing order.
function RenderLayerGroup:get_order()
  return self.order
end

-- Changes the shared view applied to the complete group.
function RenderLayerGroup:set_view(view)
  self.view = view
end

-- Enables or disables the complete layer group.
function RenderLayerGroup:set_enabled(enabled)
  self.enabled = enabled == true
end

-- Adds one child layer or nested layer group.
function RenderLayerGroup:add(layer)
  self.layers:add(layer)
end

-- Returns one direct child layer by name.
function RenderLayerGroup:get(name)
  return self.layers:get(name)
end

-- Draws all child layers through the group's shared view.
function RenderLayerGroup:draw(context)
  if not self.enabled then return end

  if self.view ~= nil then
    assert(type(self.view.begin) == "function" and type(self.view.finish) == "function",
      "render layer group view must expose begin and finish")
    self.view:begin(context)
  end

  self.layers:draw(context)

  if self.view ~= nil then self.view:finish(context) end
end

return RenderLayerGroup
