---@meta

---@class FadeTransitionFields
---@field cover_duration number Seconds needed to cover the screen.
---@field reveal_duration number Seconds needed to reveal the destination.
---@field elapsed number Time accumulated within the current phase.
---@field revealing boolean Whether destination application has started the reveal.
---@field alpha number Current overlay opacity.

---@class MapCameraCutOptions
---@field control CameraPositionControl Camera position owner.
---@field bounds MapBoundsConstraint Constraint belonging to the same camera.
---@field target Entity Entity whose XY map location is observed.
---@field create_effect fun(): table Creates an exclusive effect instance.
---@field retain_map fun(id: string): fun() Acquires a map requirement and returns its release.
---@field acquire? fun(): fun() Optional capability acquisition, returning its release.

---@class MapCameraCutFields
---@field control CameraPositionControl Camera position owner.
---@field bounds MapBoundsConstraint Constraint belonging to the same camera.
---@field create_effect fun(): table Creates an exclusive effect instance.
---@field retain_map fun(id: string): fun() Acquires a map requirement.
---@field acquire? fun(): fun() Optional capability acquisition.
---@field tracker MapLocationTracker Independent location observer.
---@field presented_map table? Map currently presented by the camera.
---@field runner TransitionRunner? Most recent execution.
---@field releases (fun())[] Temporary capabilities owned by the current execution.
---@field held table<string, boolean> Maps retained by this execution.
---@field recover boolean Align framing after cancellation or failure.
