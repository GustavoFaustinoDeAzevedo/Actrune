local RenderViewStack = {}
RenderViewStack.__index = RenderViewStack

-- Creates an ordered composition of render views.
function RenderViewStack.new(views)
  local self = setmetatable({}, RenderViewStack)
  self.views = views or {}

  for _, view in ipairs(self.views) do
    assert(view ~= nil and type(view.begin) == "function" and type(view.finish) == "function",
      "render view stack entries must expose begin and finish")
  end

  return self
end

-- Adds one view to the end of the transformation stack.
function RenderViewStack:add(view)
  assert(view ~= nil and type(view.begin) == "function" and type(view.finish) == "function",
    "render view must expose begin and finish")
  table.insert(self.views, view)
end

-- Applies all views in composition order.
function RenderViewStack:begin(context)
  for _, view in ipairs(self.views) do view:begin(context) end
end

-- Restores all views in reverse composition order.
function RenderViewStack:finish(context)
  for index = #self.views, 1, -1 do self.views[index]:finish(context) end
end

return RenderViewStack
