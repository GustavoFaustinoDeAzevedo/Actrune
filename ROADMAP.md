# Actrune roadmap

## 0.6.0 — Map-aware camera framing and transitions

Status: implementation available; zero-duration fade correction and release acceptance pending.

### Goal

Configure orthographic camera framing and map transition presentation through project data while preserving existing cameras, entities, and gameplay state.

### Implemented

- Per-map camera bounds with shared rectangles and global fallback.
- Immediate initial framing and configurable automatic bounds interpolation.
- Bounds calculation accounting for viewport size, zoom, rotation, and small regions.
- Unrestricted tracking along periodic axes and continued entity elevation tracking.
- Reusable camera cuts with fade and camera slides with selectable curves.
- A generic transition runner with cancellation and cleanup.
- Optional suspension of runtime systems and event execution while presentation continues.
- Independent suspension ownership and temporary map activity requirements.
- Directional preset selection with a configurable default.
- Validation of map references, preset references, and layout compatibility.
- Independent controller state for each camera.
- An integrated three-map demonstration.

### Behavior contracts

- Camera bounds do not define map membership or movement boundaries.
- The configured camera target determines the observed map.
- Missing map bounds use global bounds, or unrestricted tracking when none exist.
- Equal bounds avoid redundant bounds interpolation. A configured map transition may still execute between those maps.
- Automatic bounds duration, slide duration, and fade durations are separate settings.
- Built-in transition controllers select destination bounds directly and control their own presentation timing.
- Simulation suspension begins on the next simulation update after acquisition.
- Suspended event runners retain their state; simulation-driven animations pause while graphics remain drawable.
- A preset is selected once per transition and remains selected until that execution and any recovery finish.
- Cancellation releases temporary requirements and aligns framing with the current target on the next update.
- Cancellation does not undo an already applied destination.

### Remaining work

- [ ] Complete a zero-duration fade in the same update without an extra covered frame or suspended simulation update.
- [ ] Visually verify east_hall to south_hall with slide and the return path with fade.
- [ ] Verify shared framing, initial framing, and fallback behavior in the demonstration.
- [ ] Verify paused and free transitions, input handling, and preserved event state.
- [ ] Verify elevation, horizontal looping, viewport changes, zoom, and rotation.
- [ ] Confirm that the existing perspective rendering mode still works.
- [ ] Complete acceptance before updating the engine version and publishing the release notes.

### Validation status

Previous isolated checks covered transition integration and Lua diagnostics. They are not a committed regression suite and do not replace visual acceptance.

### Scope boundary

This milestone covers orthographic camera framing and transition presentation. Perspective-specific transitions, map streaming, disk persistence, portal definitions, and new movement mechanics remain separate work.
