local RenderLayerStack = {}
RenderLayerStack.__index = RenderLayerStack

-- Creates an ordered collection of render layers.
function RenderLayerStack.new()
  return setmetatable({
    layers = {},
    layers_by_name = {}
  }, RenderLayerStack)
end

-- Sorts layers deterministically by order and name.
local function compare_layers(a, b)
  if a:get_order() ~= b:get_order() then return a:get_order() < b:get_order() end
  return a:get_name() < b:get_name()
end

-- Adds one named render layer to the stack.
function RenderLayerStack:add(layer)
  assert(layer ~= nil, "render layer stack requires a layer")

  local name = layer:get_name()
  assert(self.layers_by_name[name] == nil, "render layer is already registered: " .. name)

  table.insert(self.layers, layer)
  self.layers_by_name[name] = layer
  table.sort(self.layers, compare_layers)
end

-- Returns one render layer by name.
function RenderLayerStack:get(name)
  return self.layers_by_name[name]
end

-- Draws every enabled layer in deterministic order.
function RenderLayerStack:draw(context)
  for _, layer in ipairs(self.layers) do layer:draw(context) end
end

return RenderLayerStack
