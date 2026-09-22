---@meta

---@alias TransitionStep "running"|"apply"|"done"
---@alias TransitionStatus "idle"|"running"|"completed"|"cancelled"|"failed"

---@class TransitionEffect
---@field update fun(self: TransitionEffect, dt: number, applied: boolean): TransitionStep Advances effect state; done completes after destination application.
---@field draw? fun(self: TransitionEffect, context: any) Draws current state without advancing it.

---@class TransitionRunnerOptions
---@field effect TransitionEffect Exclusive effect instance for this execution.
---@field apply_destination fun() Applies the destination synchronously; called at most once.
---@field on_begin? fun() Acquires temporary state; requires on_finish.
---@field on_finish? fun(status: TransitionStatus, applied: boolean) Releases acquired state, including partial begin state; must tolerate partial setup.

---@class TransitionRunnerFields
---@field effect TransitionEffect Effect owned by this execution.
---@field apply_destination fun() Injected destination application.
---@field on_begin? fun() Optional acquisition hook.
---@field on_finish? fun(status: TransitionStatus, applied: boolean) Cleanup hook cleared before invocation.
---@field status TransitionStatus Current lifecycle status.
---@field applied boolean True only after successful destination application.
---@field busy boolean Prevents lifecycle reentry from effects and hooks.
