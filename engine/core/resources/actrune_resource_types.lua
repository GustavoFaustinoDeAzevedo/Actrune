local InputMapFactory = require("engine.core.input.input_map_factory")
local GridMetricsFactory = require("engine.world.grid.grid_metrics_factory")
local ControlProfileFactory = require("engine.world.control.control_profile_factory")
local PhysicalMaterialFactory = require("engine.world.physics.physical_material_factory")
local ImageResourceFactory = require("engine.render.image_resource_factory")
local ImageRegionFactory = require("engine.render.image_region_factory")

local ActruneResourceTypes = {}

-- Registers the built-in Actrune resource types in a project configuration register.
function ActruneResourceTypes.register(register)
  assert(register ~= nil, "Actrune resource types require a project configuration register")

  register:register_resource_type("image", ImageResourceFactory.create, {
    fields = {
      { name = "path", type = "string", required = true }
    }
  })

  register:register_resource_type("image_region", ImageRegionFactory.create, {
    fields = {
      {
        name = "image",
        type = "resource_reference",
        resource_type = "image",
        required = true
      },
      {
        name = "x",
        type = "number",
        min = 0,
        default = 0
      },
      {
        name = "y",
        type = "number",
        min = 0,
        default = 0
      },
      {
        name = "width",
        type = "number",
        required = true,
        min_exclusive = 0
      },
      {
        name = "height",
        type = "number",
        required = true,
        min_exclusive = 0
      }
    }
  })

  register:register_resource_type("physical_material", PhysicalMaterialFactory.create, {
    fields = {
      {
        name = "properties",
        type = "property_map",
        allow_custom = true,
        suggestions = {
          { name = "density",     type = "number", min = 0 },
          { name = "restitution", type = "number", min = 0 },
          { name = "friction",    type = "number", min = 0 }
        }
      }
    }
  })

  register:register_resource_type("grid_metrics", GridMetricsFactory.create, {
    fields = {
      { name = "cell_width",  type = "number", required = true, min_exclusive = 0 },
      { name = "cell_height", type = "number", required = true, min_exclusive = 0 }
    }
  })

  register:register_resource_type("input_map", InputMapFactory.create)
  register:register_resource_type("control_profile", ControlProfileFactory.create)
end

return ActruneResourceTypes
