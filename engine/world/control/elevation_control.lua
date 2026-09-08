local ElevationMover = require("engine.world.spatial.elevation_mover")

---@class ElevationControl: ElevationControlFields
local ElevationControl = {}
ElevationControl.__index = ElevationControl

--- Creates an unbound vertical control from resolved policies and component names.
--- Call bind_control before update_control; construction does not move the entity.
---@param options ElevationControlOptions Input, movement dependencies and resolved policies.
---@return ElevationControl control New component awaiting binding.
function ElevationControl.new(options)
  assert(type(options) == "table", "elevation control requires options")
  assert(type(options.input) == "string", "elevation control requires an input name")
  assert(options.amount ~= nil and type(options.amount.resolve) == "function",
    "elevation control requires a resolvable amount")
  assert(options.application ~= nil and type(options.application.should_apply) == "function",
    "elevation control requires an application policy")

  return setmetatable({
    controls = options.controls or "controls",
    input = options.input,
    amount = options.amount,
    application = options.application,
    movement = {
      elevation_component = options.elevation_component,
      source_shape = options.source_shape,
      target_shape = options.target_shape,
      source_vertical_range = options.source_vertical_range,
      target_vertical_range = options.target_vertical_range
    }
  }, ElevationControl)
end

--- Resolves the control profile and creates a mover bound to this entity.
--- Retains live component references; call again if those components are replaced.
--- Does not reset the application policy's internal state.
---@param world table World used for movement collision queries.
---@param entity table Entity containing the configured control and movement components.
function ElevationControl:bind_control(world, entity)
  self.control_profile = entity:get_component(self.controls)
  assert(self.control_profile ~= nil and type(self.control_profile.resolve_axis) == "function",
    "elevation control references invalid controls component: " .. self.controls)

  self.mover = ElevationMover.new(world, entity, self.movement)
  self.entity = entity
end

--- Reads the configured axis and requests movement when the application policy allows it.
--- Calls the policy even for inactive input so stateful policies can reset.
--- Resolves the amount only when movement is requested; dt scaling belongs to that expression.
--- The policy context includes active, direction, dt, entity and runtime.
---@param runtime table Runtime used to resolve logical input and policy context.
---@param dt number Elapsed update time in seconds.
---@return number|nil applied Actual displacement, or nil when no movement was requested.
---@return table|nil contact Contact entity when reported by the mover.
function ElevationControl:update_control(runtime, dt)
  assert(self.mover ~= nil, "elevation control is not bound")

  local direction = self.control_profile:resolve_axis(self.input, runtime)
  local context = {
    active = direction ~= 0,
    direction = direction,
    dt = dt,
    entity = self.entity,
    runtime = runtime
  }

  if not self.application:should_apply(context) or direction == 0 then return end

  return self.mover:try_move(direction * self.amount:resolve(context))
end

return ElevationControl
