local ResourceSequence = require("engine.core.resources.resource_sequence")

local ResourceSequenceFactory = {}

-- Creates a resource factory that resolves every sequence item as one fixed resource type.
function ResourceSequenceFactory.for_type(resource_type)
  assert(type(resource_type) == "string" and resource_type ~= "",
    "resource sequence factory requires a non-empty resource type")

  return function(definition, context)
    assert(type(definition) == "table", "resource sequence definition must be a table")
    assert(type(definition.items) == "table" and #definition.items > 0,
      "resource sequence requires at least one item")
    assert(context ~= nil and type(context.resolve_resource) == "function",
      "resource sequence factory requires resource resolution")

    local items = {}

    for index, name in ipairs(definition.items) do
      assert(type(name) == "string" and name ~= "",
        "resource sequence item must be a non-empty resource name at index " .. index)

      items[index] = context.resolve_resource(resource_type, name)
    end

    return ResourceSequence.new(items)
  end
end

return ResourceSequenceFactory
