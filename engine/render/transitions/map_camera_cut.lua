local MapCameraTransition = require("engine.render.transitions.map_camera_transition")

local MapCameraCut = {}

--- Composes an immediate camera cut with an independently selected screen effect.
---@param options MapCameraCutOptions Camera, effect and temporary capabilities.
---@return MapCameraTransition controller Independent transition controller.
function MapCameraCut.new(options)
  return MapCameraTransition.new({
    control = options.control,
    bounds = options.bounds,
    target = options.target,
    create_effect = options.create_effect,
    retain_map = options.retain_map,
    acquire = options.acquire,
    apply_position = function(control) control:snap() end
  })
end

return MapCameraCut
