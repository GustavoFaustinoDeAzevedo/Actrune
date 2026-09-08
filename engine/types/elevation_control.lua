---@meta

---@class ElevationControlOptions: ElevationMoverOptions
---@field controls? string Control profile component name. Defaults to "controls".
---@field input string Logical axis name in the control profile.
---@field amount table Resolved expression exposing resolve(context).
---@field application table Resolved policy exposing should_apply(context).

---@class ElevationControlFields
---@field controls string Control profile component name.
---@field input string Logical axis name.
---@field amount table Expression that resolves displacement magnitude.
---@field application table Policy that decides when to request movement.
---@field movement ElevationMoverOptions Names forwarded when creating the mover.
---@field mover ElevationMover? Movement operation; unavailable before binding.
---@field control_profile table Live profile assigned by bind_control; use only after binding.
---@field entity table Entity assigned by bind_control; use only after binding.
