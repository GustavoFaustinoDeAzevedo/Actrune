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

  ActruneValueExpressionTypes.register(catalog)
  ActruneConditionExpressionTypes.register(catalog)
  ActruneDirectionPolicyTypes.register(catalog)
  ActruneDisplacementExpressionTypes.register(catalog)
  ActruneControlApplicationTypes.register(catalog)
  ActruneEntityTypes.register(catalog)
  ActruneEventTypes.register(catalog)

  return catalog
end

return ActruneTypeCatalog
