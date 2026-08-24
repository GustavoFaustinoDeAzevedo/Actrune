local love = require "love"
local Box2DBackend = {}

Box2DBackend.__index = Box2DBackend

-- Returns a Box2D property from an optional Actrune physical material.
local function get_material_value(material, name, fallback)
  if material == nil then return fallback end
  return material:get(name, fallback)
end

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

-- Creates a circular Box2D body optionally attached to an Actrune entity.
function Box2DBackend:create_circle(id, x, y, radius, options)
  options = options or {}

  local material = options.material
  local body_type = options.body_type or "dynamic"
  local density = options.density or get_material_value(material, "density", 1)
  local restitution = options.restitution or get_material_value(material, "restitution", 0)
  local friction = options.friction or get_material_value(material, "friction", 0)

  local body = love.physics.newBody(self.world, x, y, body_type)
  local shape = love.physics.newCircleShape(radius)
  local fixture = love.physics.newFixture(body, shape, density)

  fixture:setRestitution(restitution)
  fixture:setFriction(friction)

  local entry = {
    id = id,
    entity = options.entity,
    body = body,
    shape = shape,
    fixture = fixture,
    material = material
  }

  self.bodies[id] = entry

  return entry
end

-- Creates a rectangular Box2D body optionally attached to an Actrune entity.
function Box2DBackend:create_rectangle(id, x, y, width, height, options)
  options = options or {}

  local material = options.material
  local body_type = options.body_type or "static"
  local density = options.density or get_material_value(material, "density", 1)
  local restitution = options.restitution or get_material_value(material, "restitution", 0)
  local friction = options.friction or get_material_value(material, "friction", 0)

  local body = love.physics.newBody(self.world, x, y, body_type)
  local shape = love.physics.newRectangleShape(width, height)
  local fixture = love.physics.newFixture(body, shape, density)

  fixture:setRestitution(restitution)
  fixture:setFriction(friction)

  local entry = {
    id = id,
    entity = options.entity,
    body = body,
    shape = shape,
    fixture = fixture,
    material = material
  }

  self.bodies[id] = entry

  return entry
end

-- Attaches an Actrune entity to an existing Box2D body entry.
function Box2DBackend:attach_entity(entity, entry)
  assert(entity ~= nil, "entity is required")
  assert(entry ~= nil and entry.body ~= nil, "Box2D body entry is required")

  entry.entity = entity
  self.bodies[entry.id] = entry

  return entry
end

-- Synchronizes Box2D-controlled bodies back to their Actrune entities.
function Box2DBackend:sync_entities()
  for _, entry in pairs(self.bodies) do
    if entry.entity ~= nil and entry.body:getType() ~= "static" then
      entry.entity.transform.x = entry.body:getX()
      entry.entity.transform.y = entry.body:getY()
      entry.entity.transform.rotation = entry.body:getAngle()
    end
  end
end

-- Advances Box2D and synchronizes its resulting transforms.
function Box2DBackend:update(dt)
  self.world:update(dt)
  self:sync_entities()
end

return Box2DBackend
