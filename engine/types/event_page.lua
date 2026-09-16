---@meta

---@class EventPageOptions
---@field commands table[] Runtime command instances.
---@field trigger table Trigger exposing matches.
---@field condition? fun(context: table): boolean Optional page availability condition.
---@field required_maps? string[] Additional maps required throughout this page's execution.

---@class EventPageFields
---@field commands table[] Commands retained by each runner using this page.
---@field trigger table Runtime trigger.
---@field condition? fun(context: table): boolean Optional page availability condition.
---@field required_maps string[] Read-only copied map identifiers; does not imply neighbor retention.
