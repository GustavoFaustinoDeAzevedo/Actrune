local love = require "love"

local ShaderCanvasPresenter = {}
ShaderCanvasPresenter.__index = ShaderCanvasPresenter

-- Creates a canvas presenter that renders through an arbitrary shader.
function ShaderCanvasPresenter.new(options)
  options = options or {}

  assert(options.shader ~= nil, "shader canvas presenter requires a shader")

  local self = setmetatable({}, ShaderCanvasPresenter)
  self.shader = type(options.shader) == "string" and love.graphics.newShader(options.shader) or options.shader
  self.uniforms = options.uniforms or {}
  self.uniform_provider = options.uniform_provider

  assert(type(self.uniforms) == "table", "shader canvas presenter uniforms must be a table")
  assert(self.uniform_provider == nil or type(self.uniform_provider) == "function",
    "shader canvas presenter uniform_provider must be nil or a function")

  return self
end

-- Changes one static shader uniform value.
function ShaderCanvasPresenter:set_uniform(name, value)
  self.uniforms[name] = value
end

-- Removes one static shader uniform value.
function ShaderCanvasPresenter:remove_uniform(name)
  self.uniforms[name] = nil
end

-- Sends one collection of available uniform values to the shader.
function ShaderCanvasPresenter:_send_uniforms(values)
  for name, value in pairs(values) do
    if self.shader:hasUniform(name) then self.shader:send(name, value) end
  end
end

-- Presents an offscreen canvas through the configured shader.
function ShaderCanvasPresenter:present(canvas, context)
  self:_send_uniforms(self.uniforms)

  if self.uniform_provider ~= nil then
    local dynamic_uniforms = self.uniform_provider(canvas, context) or {}
    assert(type(dynamic_uniforms) == "table", "shader canvas presenter uniform_provider must return a table")
    self:_send_uniforms(dynamic_uniforms)
  end

  love.graphics.setShader(self.shader)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(canvas, 0, 0)
  love.graphics.setShader()
end

return ShaderCanvasPresenter
