local CameraElevationControl = {}
CameraElevationControl.__index = CameraElevationControl

-- Resolves the absolute camera destination from a live source and a fixed offset.
function CameraElevationControl:_get_target()
  local elevation = self.source:get_elevation()
  assert(type(elevation) == "number"
    and elevation > -math.huge and elevation < math.huge,
    "camera elevation source must return a finite value")

  local target = elevation + self.offset
  assert(target > -math.huge and target < math.huge,
    "camera elevation target must be finite")
  return target
end

-- Starts at the target height to avoid a startup transition from an unrelated level.
function CameraElevationControl.new(destination, source, options)
  options = options or {}

  assert(destination ~= nil and type(destination.set_camera_elevation) == "function",
    "camera elevation control requires a destination exposing set_camera_elevation")
  assert(source ~= nil and type(source.get_elevation) == "function",
    "camera elevation control requires a source exposing get_elevation")

  local offset = options.offset or 0
  local half_life = options.half_life or 0

  assert(type(offset) == "number" and offset > -math.huge and offset < math.huge,
    "camera elevation offset must be finite")
  assert(type(half_life) == "number" and half_life >= 0 and half_life < math.huge,
    "camera elevation half-life must be finite and non-negative")

  local self = setmetatable({
    destination = destination,
    source = source,
    offset = offset,
    half_life = half_life
  }, CameraElevationControl)

  self.current = self:_get_target()
  self.destination:set_camera_elevation(self.current)
  return self
end

-- Follows elevation with exponential smoothing independent from horizontal tracking.
function CameraElevationControl:update(dt)
  assert(type(dt) == "number" and dt >= 0 and dt < math.huge,
    "camera elevation delta time must be finite and non-negative")
  if dt == 0 then return end

  local target = self:_get_target()
  if target == self.current then return end

  local response = self.half_life == 0 and 1 or 1 - 0.5 ^ (dt / self.half_life)
  self.current = self.current + (target - self.current) * response
  self.destination:set_camera_elevation(self.current)
end

return CameraElevationControl
