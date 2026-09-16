local love = require "love"
local PhysicsShapeCompiler = require("engine.world.physics.physics_shape_compiler")

local Box2DBackend = {}
Box2DBackend.__index = Box2DBackend

local CAPABILITIES = {
  max_polygon_vertices = 8,
  boundary_loop = true
}

-- Returns a Box2D property from an optional Actrune physical material.
local function get_material_value(material, name, fallback)
  if material == nil then return fallback end
  return material:get(name, fallback)
end

-- Creates a Box2D shape from one compiled Actrune physics part.
local function create_box2d_shape(part)
  if part.type == "circle" then
    return love.physics.newCircleShape(part.offset_x, part.offset_y, part.radius)
  end

  if part.type == "polygon" then
    return love.physics.newPolygonShape(part.vertices)
  end

  if part.type == "boundary_loop" then
    return love.physics.newChainShape(true, part.vertices)
  end

  error("unsupported compiled physics shape: " .. tostring(part.type))
end

-- Creates all Box2D fixtures required to represent one Actrune spatial shape.
local function create_fixtures(body, entity, shape_name, shape, body_type)
  local material = shape:get_material()
  local density = get_material_value(material, "density", 1)
  local restitution = get_material_value(material, "restitution", 0)
  local friction = get_material_value(material, "friction", 0)

  local compiled_parts, compilation_error =
      PhysicsShapeCompiler.compile(shape, body_type, CAPABILITIES)

  assert(
    compiled_parts ~= nil,
    "cannot compile physics shape '" .. shape_name .. "': " .. tostring(compilation_error)
  )

  local fixtures = {}

  for part_index, part in ipairs(compiled_parts) do
    local box2d_shape = create_box2d_shape(part)
    local fixture = love.physics.newFixture(body, box2d_shape, density)

    fixture:setRestitution(restitution)
    fixture:setFriction(friction)

    fixture:setUserData({
      entity = entity,
      shape_name = shape_name,
      part_index = part_index
    })

    table.insert(fixtures, {
      compiled_part = part,
      shape = box2d_shape,
      fixture = fixture
    })
  end

  return {
    shape_name = shape_name,
    source_shape = shape,
    fixtures = fixtures,
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

-- Returns the physical shape capabilities supported by this backend.
function Box2DBackend:get_shape_capabilities()
  return CAPABILITIES
end

-- Validates whether an entity's rigid body can be represented by this backend.
function Box2DBackend:validate_entity(entity)
  assert(entity ~= nil, "entity is required")

  local rigid_body = entity:get_component("rigid_body")
  if rigid_body == nil then return false, "entity does not have a rigid_body component" end

  for _, shape_name in ipairs(rigid_body:get_shapes()) do
    local shape = entity:get_shape(shape_name)

    if shape == nil then
      return false, "rigid body references missing shape: " .. shape_name
    end

    local valid, error_message =
        PhysicsShapeCompiler.validate(shape, rigid_body:get_body_type(), CAPABILITIES)

    if not valid then
      return false, "shape '" .. shape_name .. "': " .. error_message
    end
  end

  return true
end

-- Registers an Actrune entity containing a rigid body component.
function Box2DBackend:add_entity(entity)
  assert(entity ~= nil, "entity is required")
  assert(self.entry_by_entity[entity] == nil, "entity is already registered in Box2D")

  local valid, validation_error = self:validate_entity(entity)
  assert(valid, validation_error)

  local rigid_body = entity:get_component("rigid_body")

  assert(
    entity.transform.scale_x == 1 and entity.transform.scale_y == 1,
    "Box2D entity scaling is not supported yet"
  )

  local body_type = rigid_body:get_body_type()
  local body = love.physics.newBody(
    self.world,
    entity.transform.x,
    entity.transform.y,
    body_type
  )

  body:setAngle(entity.transform.rotation)
  body:setActive(entity:is_active())

  local entry = {
    entity = entity,
    rigid_body = rigid_body,
    body = body,
    fixtures = {}
  }

  for _, shape_name in ipairs(rigid_body:get_shapes()) do
    local shape = entity:get_shape(shape_name)
    entry.fixtures[shape_name] = create_fixtures(body, entity, shape_name, shape, body_type)
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
    if entry.body:isActive() and entry.body:getType() == "dynamic" then
      entry.entity.transform.x = entry.body:getX()
      entry.entity.transform.y = entry.body:getY()
      entry.entity.transform.rotation = entry.body:getAngle()
    end
  end
end

--- Applies activity outside Box2D stepping while retaining bodies and fixtures.
--- Restoring a body uses the entity transform and preserves its stored velocity.
function Box2DBackend:sync_activity()
  for _, entry in ipairs(self.entries) do
    local body = entry.body
    local active = entry.entity:is_active()
    if body:isActive() ~= active then
      if active then
        body:setPosition(entry.entity.transform.x, entry.entity.transform.y)
        body:setAngle(entry.entity.transform.rotation)
      end
      body:setActive(active)
    end
  end
end

--- Advances active bodies and synchronizes only their resulting transforms.
function Box2DBackend:update(dt)
  self:sync_activity()
  self.world:update(dt)
  self:sync_entities()
end

return Box2DBackend
