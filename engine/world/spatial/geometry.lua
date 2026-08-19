local Geometry = {}

Geometry.EPSILON = 0.000001

-- Calculates the signed cross product used for orientation tests.
function Geometry.cross(ax, ay, bx, by, cx, cy)
  return (bx - ax) * (cy - ay)
      - (by - ay) * (cx - ax)
end

-- Calculates the cross product between two vectors.
function Geometry.vector_cross(ax, ay, bx, by)
  return ax * by - ay * bx
end

-- Calculates the dot product between two vectors.
function Geometry.dot(ax, ay, bx, by)
  return ax * bx + ay * by
end

-- Clamps a numeric value between minimum and maximum bounds.
function Geometry.clamp(value, minimum, maximum)
  return math.max(
    minimum,
    math.min(maximum, value)
  )
end

-- Returns whether a point lies on a line segment.
function Geometry.point_on_segment(
    px,
    py,
    ax,
    ay,
    bx,
    by
)
  local cross =
      Geometry.cross(
        ax,
        ay,
        bx,
        by,
        px,
        py
      )

  if math.abs(cross) > Geometry.EPSILON then
    return false
  end

  return px >= math.min(ax, bx) - Geometry.EPSILON
      and px <= math.max(ax, bx) + Geometry.EPSILON
      and py >= math.min(ay, by) - Geometry.EPSILON
      and py <= math.max(ay, by) + Geometry.EPSILON
end

-- Returns whether two line segments intersect or touch.
function Geometry.segments_intersect(
    ax,
    ay,
    bx,
    by,
    cx,
    cy,
    dx,
    dy
)
  local ab_c =
      Geometry.cross(
        ax,
        ay,
        bx,
        by,
        cx,
        cy
      )

  local ab_d =
      Geometry.cross(
        ax,
        ay,
        bx,
        by,
        dx,
        dy
      )

  local cd_a =
      Geometry.cross(
        cx,
        cy,
        dx,
        dy,
        ax,
        ay
      )

  local cd_b =
      Geometry.cross(
        cx,
        cy,
        dx,
        dy,
        bx,
        by
      )

  if (
        (ab_c > Geometry.EPSILON and ab_d < -Geometry.EPSILON)
        or
        (ab_c < -Geometry.EPSILON and ab_d > Geometry.EPSILON)
      )
      and (
        (cd_a > Geometry.EPSILON and cd_b < -Geometry.EPSILON)
        or
        (cd_a < -Geometry.EPSILON and cd_b > Geometry.EPSILON)
      )
  then
    return true
  end

  if math.abs(ab_c) <= Geometry.EPSILON
      and Geometry.point_on_segment(
        cx,
        cy,
        ax,
        ay,
        bx,
        by
      )
  then
    return true
  end

  if math.abs(ab_d) <= Geometry.EPSILON
      and Geometry.point_on_segment(
        dx,
        dy,
        ax,
        ay,
        bx,
        by
      )
  then
    return true
  end

  if math.abs(cd_a) <= Geometry.EPSILON
      and Geometry.point_on_segment(
        ax,
        ay,
        cx,
        cy,
        dx,
        dy
      )
  then
    return true
  end

  if math.abs(cd_b) <= Geometry.EPSILON
      and Geometry.point_on_segment(
        bx,
        by,
        cx,
        cy,
        dx,
        dy
      )
  then
    return true
  end

  return false
end

-- Returns whether two segments cross through their interiors rather than only touching.
function Geometry.segments_properly_intersect(
    ax,
    ay,
    bx,
    by,
    cx,
    cy,
    dx,
    dy
)
  local ab_c =
      Geometry.cross(
        ax,
        ay,
        bx,
        by,
        cx,
        cy
      )

  local ab_d =
      Geometry.cross(
        ax,
        ay,
        bx,
        by,
        dx,
        dy
      )

  local cd_a =
      Geometry.cross(
        cx,
        cy,
        dx,
        dy,
        ax,
        ay
      )

  local cd_b =
      Geometry.cross(
        cx,
        cy,
        dx,
        dy,
        bx,
        by
      )

  local crosses_ab =
      (
        ab_c > Geometry.EPSILON
        and ab_d < -Geometry.EPSILON
      )
      or
      (
        ab_c < -Geometry.EPSILON
        and ab_d > Geometry.EPSILON
      )

  local crosses_cd =
      (
        cd_a > Geometry.EPSILON
        and cd_b < -Geometry.EPSILON
      )
      or
      (
        cd_a < -Geometry.EPSILON
        and cd_b > Geometry.EPSILON
      )

  return crosses_ab and crosses_cd
end

-- Finds where a moving point crosses a static line segment.
function Geometry.moving_point_segment_fraction(
    point_x,
    point_y,
    move_x,
    move_y,
    start_x,
    start_y,
    end_x,
    end_y
)
  local segment_x = end_x - start_x
  local segment_y = end_y - start_y
  local relative_x = start_x - point_x
  local relative_y = start_y - point_y

  local denominator =
      Geometry.vector_cross(
        move_x,
        move_y,
        segment_x,
        segment_y
      )

  if math.abs(denominator) <= Geometry.EPSILON
  then
    return nil
  end

  local movement_fraction =
      Geometry.vector_cross(
        relative_x,
        relative_y,
        segment_x,
        segment_y
      )
      / denominator

  local segment_fraction =
      Geometry.vector_cross(
        relative_x,
        relative_y,
        move_x,
        move_y
      )
      / denominator

  if movement_fraction < -Geometry.EPSILON
      or movement_fraction > 1 + Geometry.EPSILON
      or segment_fraction < -Geometry.EPSILON
      or segment_fraction > 1 + Geometry.EPSILON
  then
    return nil
  end

  return Geometry.clamp(movement_fraction, 0, 1)
end

return Geometry
