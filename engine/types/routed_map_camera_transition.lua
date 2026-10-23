---@meta

---@class CameraTransitionContext
---@field control CameraPositionControl Shared position control.
---@field bounds MapBoundsConstraint Shared bounds belonging to this camera.
---@field target Entity Map location source.
---@field retain_map fun(id: string): fun() Acquires one temporary map requirement.
---@field suspend? fun(): fun() Acquires one simulation suspension.

---@class RoutedCameraController
---@field start fun(self: RoutedCameraController, previous: MapRegion?): boolean Starts from an explicit source.
---@field update fun(self: RoutedCameraController, dt: number, simulation_dt?: number) Advances presentation.
---@field draw fun(self: RoutedCameraController, context?: any) Draws the current effect.
---@field cancel fun(self: RoutedCameraController): boolean Cancels and releases temporary requirements.
---@field is_busy fun(self: RoutedCameraController): boolean Includes pending recovery.
---@field get_presented_map fun(self: RoutedCameraController): MapRegion? Last applied destination.

---@class CameraTransitionPreset
---@field create fun(self: CameraTransitionPreset, options: CameraTransitionContext): RoutedCameraController Creates independent state.

---@class RoutedMapCameraTransitionFields
---@field options CameraTransitionContext Read-only composition capabilities.
---@field tracker MapLocationTracker Independent location observer.
---@field select_preset fun(previous: MapRegion?, current: MapRegion?): CameraTransitionPreset? Resolved lookup; nil keeps ordinary following.
---@field presented_map MapRegion? Last destination of a settled execution.
---@field active RoutedCameraController? Controller retained until it settles.
