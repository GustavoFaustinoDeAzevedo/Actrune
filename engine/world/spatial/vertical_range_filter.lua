local VerticalRangeFilter = {}

-- Creates a candidate filter using independently named vertical body ranges.
function VerticalRangeFilter.create(entity, source_name, target_name)
  assert(entity ~= nil and type(entity.get_component) == "function",
    "vertical range filter requires an entity exposing get_component")
  assert(type(source_name) == "string" and source_name ~= "",
    "vertical range filter requires a source component name")
  assert(type(target_name) == "string" and target_name ~= "",
    "vertical range filter requires a target component name")

  local source = entity:get_component(source_name)

  assert(source ~= nil and type(source.get_bounds) == "function",
    "vertical range filter requires source component: " .. source_name)

  -- The source component is resolved once while its bounds remain live.
  return function(target_entity)
    local target = target_entity:get_component(target_name)

    assert(target ~= nil and type(target.get_bounds) == "function",
      "vertical range filter requires target component: "
      .. tostring(target_entity.id) .. "." .. target_name)

    local source_min, source_max = source:get_bounds(entity)
    local target_min, target_max = target:get_bounds(target_entity)

    assert(source_max > source_min and target_max > target_min,
      "vertical collision ranges must have positive height")

    return source_min < target_max and target_min < source_max
  end
end

return VerticalRangeFilter
