local AnimationPlayer = require("engine.core.animation.animation_player")

local AnimatedEntityVisual = {}
AnimatedEntityVisual.__index = AnimatedEntityVisual

-- Creates one runtime visual instance with independent animation playback for an entity.
function AnimatedEntityVisual.new(entity_id, entity, visual_template)
  assert(type(entity_id) == "string" and entity_id ~= "",
    "animated entity visual requires a non-empty entity id")
  assert(entity ~= nil, "animated entity visual requires an entity")
  assert(type(entity.get_position) == "function",
    "animated entity visual entity must expose get_position")
  assert(type(entity.get_rotation) == "function",
    "animated entity visual entity must expose get_rotation")
  assert(visual_template ~= nil and type(visual_template.get_clip) == "function",
    "animated entity visual requires a template exposing get_clip")
  assert(type(visual_template.instantiate) == "function",
    "animated entity visual template must expose instantiate")

  local self = setmetatable({}, AnimatedEntityVisual)
  self.entity_id = entity_id
  self.entity = entity
  self.animation = AnimationPlayer.new(visual_template:get_clip())

  self.visual = visual_template:instantiate({
    index_provider = function()
      return self.animation:get_frame_index()
    end
  })

  return self
end

-- Returns the id of the represented entity.
function AnimatedEntityVisual:get_entity_id()
  return self.entity_id
end

-- Returns the entity represented by this runtime visual instance.
function AnimatedEntityVisual:get_entity()
  return self.entity
end

-- Returns the visual used to render this entity.
function AnimatedEntityVisual:get_visual()
  return self.visual
end

-- Returns the independent animation player owned by this visual instance.
function AnimatedEntityVisual:get_animation()
  return self.animation
end

-- Returns the current world position of the represented entity.
function AnimatedEntityVisual:get_position()
  return self.entity:get_position()
end

-- Returns the current world rotation of the represented entity.
function AnimatedEntityVisual:get_rotation()
  return self.entity:get_rotation()
end

-- Advances the independent animation playback state.
function AnimatedEntityVisual:update(dt)
  self.animation:update(dt)
end

return AnimatedEntityVisual
