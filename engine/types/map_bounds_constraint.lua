---@meta

---@class MapBoundsConstraintOptions
---@field manual? boolean Select bounds explicitly instead of following the target.
---@field fallback? CameraBounds Validated global bounds; treat as read-only.
---@field constrain_x? boolean Apply horizontal bounds unless false.
---@field constrain_y? boolean Apply vertical bounds unless false.

---@class MapBoundsConstraintFields
---@field manual boolean Whether the owning controller selects bounds explicitly.
---@field configuration MapCameraBounds Shared, read-only framing configuration.
---@field tracker MapLocationTracker Independent observer of the camera target.
---@field fallback CameraBounds? Global fallback; nil permits unrestricted tracking.
---@field current_bounds CameraBounds? Currently selected destination, not interpolated bounds.
---@field entry_bounds CameraBounds Reused rectangle for returning from unrestricted tracking.
---@field constraint AxisAlignedBoundsConstraint Owned transition state and viewport constraint.
