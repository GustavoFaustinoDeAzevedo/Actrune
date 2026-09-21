---@meta

---@class AxisAlignedBoundsConstraintOptions: CameraBounds
---@field constrain_x? boolean Apply horizontal bounds unless false.
---@field constrain_y? boolean Apply vertical bounds unless false.

---@class CameraBoundsResolveContext
---@field camera table Camera exposing get_viewport, get_zoom and get_rotation.
---@field dt? number Finite non-negative seconds; nil samples without advancing.

---@class AxisAlignedBoundsConstraintFields: CameraBounds
---@field constrain_x boolean Whether horizontal bounds are applied.
---@field constrain_y boolean Whether vertical bounds are applied.
---@field start_bounds CameraBounds Reused snapshot captured when a transition starts.
---@field target_bounds CameraBounds Reused copy of the selected destination.
---@field duration number Selected transition duration in seconds.
---@field elapsed number Accumulated time, capped at duration.
