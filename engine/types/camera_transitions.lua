---@meta

---@class FadeTransitionFields: TransitionEffect
---@field cover_duration number Seconds needed to cover the screen.
---@field reveal_duration number Seconds needed to reveal the destination.
---@field elapsed number Time accumulated within the current phase.
---@field revealing boolean Whether destination application has started the reveal.
---@field alpha number Current overlay opacity.

---@class MapCameraTransitionDependencies
---@field control CameraPositionControl Camera position owner.
---@field bounds MapBoundsConstraint Constraint belonging to the same camera.
---@field target Entity Entity whose XY map location is observed.
---@field create_effect fun(): TransitionEffect Creates an exclusive effect instance.
---@field retain_map fun(id: string): fun() Acquires a map requirement and returns its release.
---@field acquire? fun(): fun() Optional capability acquisition, returning its release.

---@alias MapCameraCutOptions MapCameraTransitionDependencies

---@class MapCameraTransitionOptions: MapCameraTransitionDependencies
---@field apply_position fun(control: CameraPositionControl, effect: TransitionEffect?) Applies the selected style; nil effect requests immediate recovery.

---@class MapCameraTransitionFields
---@field control CameraPositionControl Camera position owner.
---@field bounds MapBoundsConstraint Constraint belonging to the same camera.
---@field create_effect fun(): TransitionEffect Creates an exclusive effect instance.
---@field apply_position fun(control: CameraPositionControl, effect: TransitionEffect?) Position application or recovery.
---@field retain_map fun(id: string): fun() Acquires a map requirement.
---@field acquire? fun(): fun() Optional capability acquisition.
---@field tracker MapLocationTracker Independent location observer.
---@field presented_map table? Map selected by successful destination application.
---@field runner TransitionRunner? Most recent execution.
---@field releases (fun())[] Temporary capabilities owned by the current execution.
---@field held table<string, boolean> Maps retained by this execution.
---@field recover boolean Align framing after cancellation or failure.

---@class CameraSlideTransitionFields: TransitionEffect
---@field camera table Camera exposing get_position and set_position.
---@field resolve_position fun(): number, number Constrained destination provider.
---@field curve fun(progress: number): number Movement weight in [0, 1].
---@field duration number Total movement duration in seconds.
---@field elapsed number Accumulated movement time.
---@field start_x number Camera X captured at construction.
---@field start_y number Camera Y captured at construction.
