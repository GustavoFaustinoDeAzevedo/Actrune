local love = require "love"

local Box2DBackend = {}
Box2DBackend.__index = Box2DBackend

local unpack_values = table.unpack or unpack

-- Returns a Box2D property from an optional Actrune physical material.
local function get_material_value(material, name, fallback)
  if material == nil then return fallback end
  return material:get(name, fallback)
end

-- Converts an Actrune circle into a Box2D circle shape.
local function create_circle_shape(shape)
  local offset_x, offset_y = shape:get_offset()
  return love.physics.newCircleShape(offset_x, offset_y, shape:get_radius())
end

-- Converts an Actrune polygon into a Box2D polygon shape.
local function create_polygon_shape(shape)
  assert(shape:get_side_count() <= 8, "Box2D polygon conversion currently supports at most 8 vertices")

  local offset_x, offset_y = shape:get_offset()
  local points = {}

  for _, point in ipairs(shape.points) do
    table.insert(points, point.x + offset_x)
    table.insert(points, point.y + offset_y)
  end

  return love.physics.newPolygonShape(unpack_values(points))
end

-- Converts an Actrune spatial shape into its Box2D representation.
local function create_box2d_shape(shape)
  local geometry_type = shape:get_geometry_type()

  if geometry_type == "circle" then return create_circle_shape(shape) end
  if geometry_type == "polygon" then return create_polygon_shape(shape) end

  error("unsupported Box2D geometry type: " .. tostring(geometry_type))
end

-- Creates a Box2D fixture from an Actrune spatial shape.
local function create_fixture(body, entity, shape_name, shape)
  local material = shape:get_material()
  local density = get_material_value(material, "density", 1)
  local restitution = get_material_value(material, "restitution", 0)
  local friction = get_material_value(material, "friction", 0)

  local box2d_shape = create_box2d_shape(shape)
  local fixture = love.physics.newFixture(body, box2d_shape, density)

  fixture:setRestitution(restitution)
  fixture:setFriction(friction)

  fixture:setUserData({
    entity = entity,
    shape_name = shape_name
  })

  return {
    shape_name = shape_name,
    source_shape = shape,
    shape = box2d_shape,
    fixture = fixture,
    material = material
  }
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

  self.entries = {}
  self.entry_by_entity = {}

  return self
end

-- Registers an Actrune entity containing a rigid body component.
function Box2DBackend:add_entity(entity)
  assert(entity ~= nil, "entity is required")
  assert(self.entry_by_entity[entity] == nil, "entity is already registered in Box2D")

  local rigid_body = entity:get_component("rigid_body")
  assert(rigid_body ~= nil, "entity must have a rigid_body component")

  assert(
    entity.transform.scale_x == 1 and entity.transform.scale_y == 1,
    "Box2D entity scaling is not supported yet"
  )

  local body = love.physics.newBody(
    self.world,
    entity.transform.x,
    entity.transform.y,
    rigid_body:get_body_type()
  )

  body:setAngle(entity.transform.rotation)

  local entry = {
    entity = entity,
    rigid_body = rigid_body,
    body = body,
    fixtures = {}
  }

  for _, shape_name in ipairs(rigid_body:get_shapes()) do
    local shape = entity:get_shape(shape_name)
    assert(shape ~= nil, "rigid body references missing shape: " .. shape_name)

    entry.fixtures[shape_name] = create_fixture(body, entity, shape_name, shape)
  end

  table.insert(self.entries, entry)
  self.entry_by_entity[entity] = entry

  return entry
end

-- Returns the Box2D runtime entry associated with an Actrune entity.
function Box2DBackend:get_entry(entity)
  return self.entry_by_entity[entity]
end

-- Returns the current linear velocity of a registered entity.
function Box2DBackend:get_linear_velocity(entity)
  local entry = self.entry_by_entity[entity]
  assert(entry ~= nil, "entity is not registered in Box2D")
  return entry.body:getLinearVelocity()
end

-- Returns the current angular velocity of a registered entity.
function Box2DBackend:get_angular_velocity(entity)
  local entry = self.entry_by_entity[entity]
  assert(entry ~= nil, "entity is not registered in Box2D")
  return entry.body:getAngularVelocity()
end

-- Synchronizes Box2D-controlled dynamic bodies back to their Actrune entities.
function Box2DBackend:sync_entities()
  for _, entry in ipairs(self.entries) do
    if entry.body:getType() == "dynamic" then
      entry.entity.transform.x = entry.body:getX()
      entry.entity.transform.y = entry.body:getY()
      entry.entity.transform.rotation = entry.body:getAngle()
    end
  end
end

-- Advances Box2D and synchronizes resulting dynamic transforms.
function Box2DBackend:update(dt)
  self.world:update(dt)
  self:sync_entities()
end

return Box2DBackend
