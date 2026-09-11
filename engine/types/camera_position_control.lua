---@meta

---@class CameraPositionControlOptions
---@field response? table Position response exposing resolve; defaults to immediate following.
---@field constraints? table[] Ordered constraints applied after the position response.
---@field topology? WorldTopology Optional periodic selection of the complete target position.

---@class CameraPositionControlFields
---@field camera table Camera exposing get_position and set_position.
---@field policy table Position policy exposing resolve.
---@field response table Position response exposing resolve.
---@field constraints table[] Ordered final position constraints.
---@field topology WorldTopology? Optional map topology; camera coordinates remain continuous.
