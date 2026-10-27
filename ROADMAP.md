# Actrune roadmap

## 0.6.0 — Map-aware camera framing and transitions

Status: completed on 2026-10-27.

### Goal

Configure orthographic camera framing and map transition presentation through project data while preserving existing cameras, entities, and gameplay state.

### Implemented

- Continuous camera following on unconfigured routes without snapping or simulation suspension.
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

### Acceptance

The project developer confirmed that the demonstration was working correctly after the continuous camera following correction.

The accepted demonstration includes continuous map travel, directional slide and fade presets, simulation suspension, and preserved entity state.

### Validation status

Isolated integration checks covered transition timing, simulation suspension, directional preset selection, cancellation recovery, and continuous following across map boundaries and horizontal loops.

Continuous following was compared frame by frame against the camera behavior from commit 4aaf7a68cb471200a4ebd57e53e8cb07eeb02343.

Lua Language Server checked 232 Lua files without errors or warnings.

Automated checks used graphics test doubles. Visual acceptance was supplied by the project developer; automated desktop visual verification was not completed. The isolated checks are not a committed regression suite.

### Scope boundary

This milestone covers orthographic camera framing and transition presentation. Perspective-specific transitions, map streaming, disk persistence, portal definitions, and new movement mechanics remain separate work.
