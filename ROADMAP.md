# Actrune roadmap

## 0.7.0 — Explicit map transfers

Status: planned.

### Goal

Transfer existing travelling entities to declarative map destinations through event commands, preserving their identity and unrelated runtime state.

### Behavior contracts

- Destinations reference an existing layout and map.
- Destination X and Y are local to the map and resolve to global world coordinates.
- Optional destination Z represents absolute elevation; omitting it preserves the current vertical placement.
- Destination coordinates must be finite and belong to the selected map's half-open bounds.
- Invalid destinations fail before changing entity state.
- Transfers preserve the existing entity, components, and event execution context.
- Direct placement does not perform a movement sweep between source and destination.
- Physics bodies and pending movement targets must not restore the previous position after transfer.
- Camera relocation must handle discontinuous movement explicitly, including jumps larger than half a periodic world.
- Transfer completion must not depend on advancing an event scheduler suspended by its own presentation.
- Configuration is resolved during project loading and reused during execution.

### Delivery 1 — Declarative destinations

- Add reusable destination resources through the existing resource registry.
- Resolve layout, map, local coordinates, and optional Z.
- Validate map references and destination bounds during loading.
- Keep destination data independent from entities, cameras, and physics backends.
- Add LuaCATS documentation and focused validation checks.

### Delivery 2 — Event transfer command

- Register a transfer command through the existing command catalog.
- Allow the command to select the event activator or owning entity explicitly.
- Inject the narrow transfer capability and resource resolution through composition.
- Apply each command execution at most once.
- Preserve the event runner and continue subsequent commands after transfer completion.
- Reuse map activity and event dependency retention for required source and destination content.

### Delivery 3 — Runtime integration and demonstration

- Synchronize physical placement through the existing backend integration.
- Reconcile pending movement so stale targets cannot undo the relocation.
- Deliver relocation information to presentation without importing camera code into the transfer operation.
- Reuse transition presets and simulation suspension.
- Establish the correct camera reference after distant or periodic relocation.
- Demonstrate a bidirectional event-driven transfer with preserved state and optional destination Z.

### Completion criteria

- The same entity instance reaches the declared map and position.
- Omitting Z preserves vertical placement; providing Z applies the requested height.
- Invalid configuration leaves the traveller unchanged.
- Repeated command updates do not repeat the transfer.
- Controls and physics continue from the destination.
- Destination content remains available throughout presentation.
- Subsequent event commands resume without deadlocking simulation suspension.
- Continuous map travel and existing directional camera presets retain their behavior.
- Automated checks, Lua diagnostics, and visual acceptance pass before release.

### Scope boundary

The first implementation targets travelling entities already shared by the resident maps. Map-owned entity ownership migration, streaming, disk persistence, and automatic searches for unoccupied landing positions remain separate work.

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
