local AnimationPlayer = require("engine.core.animation.animation_player")
local EntityVisual = require("engine.render.entity_visual")
local EntityVisualCollection = require("engine.render.entity_visual_collection")

local AnimatedEntityVisualSystem = {}
AnimatedEntityVisualSystem.__index = AnimatedEntityVisualSystem

-- Creates entity representations with independently owned animation playback.
function AnimatedEntityVisualSystem.new(entities_by_id, configuration)
  assert(configuration ~= nil and type(configuration.get_bindings) == "function",
    "animated entity visual system requires a configuration exposing get_bindings")

  local animations = {}

  -- Builds the drawable from its template while keeping playback outside EntityVisual.
  local function create_visual(entity_id, entity, template, elevation_source)
    assert(template ~= nil and type(template.get_clip) == "function",
      "animated entity visual system requires a template exposing get_clip")
    assert(type(template.instantiate) == "function",
      "animated entity visual system requires a template exposing instantiate")

    local animation = AnimationPlayer.new(template:get_clip())

    local visual = template:instantiate({
      index_provider = function()
        return animation:get_frame_index()
      end
    })

    local representation = EntityVisual.new(
      entity_id,
      entity,
      visual,
      elevation_source
    )

    -- Playback indices match the binding order preserved by the visual collection.
    animations[#animations + 1] = animation

    return representation
  end

  local collection = EntityVisualCollection.new(
    entities_by_id,
    configuration:get_bindings(),
    create_visual
  )

  return setmetatable({
    collection = collection,
    animations = animations
  }, AnimatedEntityVisualSystem)
end

-- Returns the number of runtime representations.
function AnimatedEntityVisualSystem:get_count()
  return self.collection:get_count()
end

-- Returns one runtime representation by its one-based index.
function AnimatedEntityVisualSystem:get(index)
  return self.collection:get(index)
end

-- Returns the playback associated with one representation index.
function AnimatedEntityVisualSystem:get_animation(index)
  assert(type(index) == "number" and index % 1 == 0,
    "animated entity visual system animation index must be an integer")
  assert(index >= 1 and index <= #self.animations,
    "animated entity visual system animation index is out of range")

  return self.animations[index]
end

-- Advances only the animation players owned by this system.
function AnimatedEntityVisualSystem:update(dt)
  for index = 1, #self.animations do
    self.animations[index]:update(dt)
  end
end

return AnimatedEntityVisualSystem
