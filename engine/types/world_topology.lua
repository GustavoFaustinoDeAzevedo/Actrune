---@meta

---@class WorldTopologyOptions
---@field min_x? number Base rectangle origin X. Defaults to 0.
---@field min_y? number Base rectangle origin Y. Defaults to 0.
---@field width number Positive map width in world units.
---@field height number Positive map height in world units.
---@field loop_x? boolean Enables horizontal repetition. Defaults to false.
---@field loop_y? boolean Enables vertical repetition in the XY plane. Defaults to false.

---@class WorldTopologyFields
---@field min_x number Base rectangle origin X.
---@field min_y number Base rectangle origin Y.
---@field width number Map width and horizontal repetition period.
---@field height number Map height and vertical repetition period.
---@field loop_x boolean Whether X repeats.
---@field loop_y boolean Whether Y repeats.
