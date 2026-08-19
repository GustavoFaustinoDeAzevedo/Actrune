local MotionResult = {}
MotionResult.__index = MotionResult

-- Creates a motion result for a requested displacement.
function MotionResult.new(requested_x, requested_y)
  local self = setmetatable({}, MotionResult)

  self.requested_x = requested_x or 0
  self.requested_y = requested_y or 0

  self.applied_x = 0
  self.applied_y = 0

  self.collisions = {}
  self.contacts = {}

  return self
end

-- Adds an applied displacement to this motion result.
function MotionResult:add_applied(dx, dy)
  self.applied_x =
      self.applied_x + dx

  self.applied_y =
      self.applied_y + dy
end

-- Adds a collided entity without duplicating it.
function MotionResult:add_collision(entity)
  if entity == nil then
    return
  end

  for _, existing_entity in ipairs(self.collisions) do
    if existing_entity == entity then
      return
    end
  end

  table.insert(
    self.collisions,
    entity
  )
end

-- Adds geometric contact information produced by a collision.
function MotionResult:add_contact(
    entity,
    normal_x,
    normal_y,
    fraction
)
  self:add_collision(entity)

  table.insert(
    self.contacts,
    {
      entity = entity,
      normal_x = normal_x,
      normal_y = normal_y,
      fraction = fraction
    }
  )
end

-- Absorbs displacement, collisions, and contacts from another motion result.
function MotionResult:absorb(other)
  if other == nil then
    return
  end

  self:add_applied(
    other.applied_x,
    other.applied_y
  )

  for _, entity in ipairs(other.collisions) do
    self:add_collision(entity)
  end

  for _, contact in ipairs(other.contacts) do
    self:add_contact(
      contact.entity,
      contact.normal_x,
      contact.normal_y,
      contact.fraction
    )
  end
end

-- Returns whether any collision occurred during the motion.
function MotionResult:has_collision()
  return #self.collisions > 0
end

-- Returns the earliest contact fraction recorded by this motion result.
function MotionResult:get_first_contact_fraction()
  local earliest_fraction = nil

  for _, contact in ipairs(self.contacts) do
    if earliest_fraction == nil
        or contact.fraction < earliest_fraction
    then
      earliest_fraction = contact.fraction
    end
  end

  return earliest_fraction
end

return MotionResult
