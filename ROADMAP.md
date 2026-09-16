# Actrune roadmap

## 0.6.0 — Map-aware orthographic camera framing

Status: planned.

### Goal

Allow projects to configure orthographic camera bounds per map and transition between them while preserving the existing camera, entities, and gameplay state.

### Behavior

- Projects may associate each map with a camera bounds rectangle.
- Multiple maps may share the same bounds for uninterrupted camera tracking.
- Camera bounds remain independent from map membership and movement boundaries.
- Bounds selection follows the configured camera target.
- A configurable transition duration controls changes between bounds; zero applies them immediately.
- Initial framing is applied before the first rendered frame.
- Missing map settings and positions outside the layout use the existing global bounds, or unrestricted tracking when no global bounds exist.
- Viewport size, zoom, and rotation remain part of bounds calculation.
- Regions smaller than the viewport retain the existing centering behavior.
- Periodic axes retain unrestricted tracking along those axes.
- Entity elevation continues to affect the camera's visual target.

### Delivery 1 — Runtime bounds transitions

- Extend the existing camera bounds implementation to support changes without recreating the camera.
- Add immediate and timed transitions with documented behavior when interrupted.
- Keep camera calculations independent from map identifiers and runtime services.
- Validate initialization, transition completion, interruption, and small-region behavior.

### Delivery 2 — Declarative map configuration

- Add project resources associating map identifiers with camera bounds.
- Validate map references and numeric settings during project loading.
- Connect the configured camera target's map location to bounds selection.
- Resolve reusable configuration during loading and avoid rebuilding it every frame.
- Preserve global bounds as the fallback.

### Delivery 3 — Integrated demonstration and release

- Configure the existing three-map scene with shared and distinct camera bounds.
- Demonstrate travel in both directions and reversal during a transition.
- Verify elevation, periodic tracking, viewport changes, and preserved entity state.
- Confirm that the existing projected rendering mode still works.
- Update the changelog and engine version after acceptance.

### Completion criteria

- Camera framing changes through project data without renderer edits.
- Maps sharing bounds do not restart a camera transition.
- Timed transitions reach the selected bounds and can be interrupted without an immediate camera position jump.
- Returning to a map preserves the existing entities and their state.
- Initial framing and fallback behavior are deterministic.
- Automated checks and visual verification of the demonstration pass.

### Scope boundary

This milestone adds regional framing to the orthographic camera. Perspective-specific regional constraints, map streaming, disk persistence, and new movement mechanics remain separate milestones.
