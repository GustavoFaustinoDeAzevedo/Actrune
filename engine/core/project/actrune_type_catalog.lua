local TypeCatalog = require("engine.core.definitions.type_catalog")

local ActruneValueExpressionTypes = require("engine.core.values.actrune_value_expression_types")
local ActruneConditionExpressionTypes = require("engine.core.conditions.actrune_condition_expression_types")
local ActruneDirectionPolicyTypes = require("engine.world.movement.direction.actrune_direction_policy_types")
local ActruneDisplacementExpressionTypes = require(
  "engine.world.movement.translation.actrune_displacement_expression_types")
local ActruneControlApplicationTypes = require("engine.world.control.actrune_control_application_types")

local ActruneEntityTypes = require("engine.world.actrune_entity_types")
local ActruneEventTypes = require("engine.events.actrune_event_types")

local ActruneTypeCatalog = {}

-- Creates an isolated type catalog initialized directly with all built-in Actrune types.
function ActruneTypeCatalog.create()
  local catalog = TypeCatalog.new()

  local actrune = catalog:create_register({
    provider = "actrune"
  })

  ActruneValueExpressionTypes.register(actrune)
  ActruneConditionExpressionTypes.register(actrune)
  ActruneDirectionPolicyTypes.register(actrune)
  ActruneDisplacementExpressionTypes.register(actrune)
  ActruneControlApplicationTypes.register(actrune)
  ActruneEntityTypes.register(actrune)
  ActruneEventTypes.register(actrune)

  return catalog
end

return ActruneTypeCatalog
