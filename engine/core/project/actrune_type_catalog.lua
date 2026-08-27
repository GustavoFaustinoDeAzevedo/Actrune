local TypeCatalog = require("engine.core.definitions.type_catalog")

local ValueExpressionFactory = require("engine.core.values.value_expression_factory")
local ConditionExpressionFactory = require("engine.core.conditions.condition_expression_factory")
local DirectionPolicyFactory = require("engine.world.movement.direction.direction_policy_factory")
local DisplacementExpressionFactory = require("engine.world.movement.translation.displacement_expression_factory")
local ControlApplicationFactory = require("engine.world.control.control_application_factory")

local ActruneTypeCatalog = {}

-- Creates an isolated type catalog initialized with the built-in Actrune types.
function ActruneTypeCatalog.create()
  local catalog = TypeCatalog.new()

  catalog:register_registry("value_expression", ValueExpressionFactory.get_registry():copy())
  catalog:register_registry("condition_expression", ConditionExpressionFactory.get_registry():copy())
  catalog:register_registry("direction_policy", DirectionPolicyFactory.get_registry():copy())
  catalog:register_registry("displacement_expression", DisplacementExpressionFactory.get_registry():copy())
  catalog:register_registry("control_application", ControlApplicationFactory.get_registry():copy())

  return catalog
end

return ActruneTypeCatalog
