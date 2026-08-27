local love = require "love"

local PhysicsShapeCompiler = {}

-- Returns polygon vertices including the shape's local offset.
local function get_polygon_vertices(shape)
  local offset_x, offset_y = shape:get_offset()
  local vertices = {}

  for _, point in ipairs(shape.points) do
    table.insert(vertices, point.x + offset_x)
    table.insert(vertices, point.y + offset_y)
  end

  return vertices
end

-- Compiles a circle into a backend-independent physical representation.
local function compile_circle(shape)
  local offset_x, offset_y = shape:get_offset()

  return {
    {
      type = "circle",
      offset_x = offset_x,
      offset_y = offset_y,
      radius = shape:get_radius()
    }
  }
end

-- Compiles a polygon according to the capabilities supplied by a physics backend.
local function compile_polygon(shape, body_type, capabilities)
  local vertices = get_polygon_vertices(shape)
  local vertex_count = #vertices / 2

  if vertex_count < 3 then return nil, "polygon must contain at least 3 vertices" end

  local max_polygon_vertices = capabilities.max_polygon_vertices
  local is_convex = love.math.isConvex(vertices)

  if is_convex and (max_polygon_vertices == nil or vertex_count <= max_polygon_vertices) then
    return {
      {
        type = "polygon",
        vertices = vertices
      }
    }
  end

  if body_type == "static" and capabilities.boundary_loop then
    return {
      {
        type = "boundary_loop",
        vertices = vertices
      }
    }
  end

  if not is_convex then return nil, "moving rigid body polygons must currently be convex" end

  return nil, "polygon exceeds the physics backend vertex limit"
end

-- Compiles an Actrune spatial shape into backend-independent physical parts.
function PhysicsShapeCompiler.compile(shape, body_type, capabilities)
  assert(shape ~= nil, "shape is required")

  capabilities = capabilities or {}

  local geometry_type = shape:get_geometry_type()

  if geometry_type == "circle" then return compile_circle(shape) end
  if geometry_type == "polygon" then return compile_polygon(shape, body_type, capabilities) end

  return nil, "unsupported physics geometry type: " .. tostring(geometry_type)
end

-- Validates whether a spatial shape can be represented by the requested physics configuration.
function PhysicsShapeCompiler.validate(shape, body_type, capabilities)
  local parts, error_message = PhysicsShapeCompiler.compile(shape, body_type, capabilities)
  return parts ~= nil, error_message
end

return PhysicsShapeCompiler
