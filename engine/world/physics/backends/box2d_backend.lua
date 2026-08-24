local love = require "love"
local Box2DBackend = {}

Box2DBackend.__index = Box2DBackend

-- Creates a Box2D-backed physics simulation.
function Box2DBackend.new(options)
  options = options or {}

  local self = setmetatable({}, Box2DBackend)

  self.world = love.physics.newWorld(
    options.gravity_x or 0,
    options.gravity_y or 980,
    options.sleep ~= false
  )

  self.bodies = {}

  return self
end

-- Creates a dynamic circular body.
function Box2DBackend:create_circle(id, x, y, radius, options)
  options = options or {}

  local body = love.physics.newBody(self.world, x, y, "dynamic")
  local shape = love.physics.newCircleShape(radius)
  local fixture = love.physics.newFixture(body, shape, options.density or 1)

  fixture:setRestitution(options.restitution or 0)
  fixture:setFriction(options.friction or 0)

  local entry = {
    id = id,
    body = body,
    shape = shape,
    fixture = fixture
  }

  self.bodies[id] = entry

  return entry
end

-- Creates a static rectangular body.
function Box2DBackend:create_rectangle(id, x, y, width, height, options)
  options = options or {}

  local body = love.physics.newBody(self.world, x, y, "static")
  local shape = love.physics.newRectangleShape(width, height)
  local fixture = love.physics.newFixture(body, shape, 1)

  fixture:setRestitution(options.restitution or 0)
  fixture:setFriction(options.friction or 0)

  local entry = {
    id = id,
    body = body,
    shape = shape,
    fixture = fixture
  }

  self.bodies[id] = entry

  return entry
end

-- Advances the Box2D simulation.
function Box2DBackend:update(dt)
  self.world:update(dt)
end

return Box2DBackend
