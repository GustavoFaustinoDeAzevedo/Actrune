# Camera transitions

Camera transitions control presentation when the configured camera target changes maps. They preserve entity instances and do not teleport the target or create map connections for movement.

The current scene integration supports orthographic rendering.

## Configuration requirements

- Configure map bounds through `world_camera_map_bounds`.
- Configure the observed entity through `world_camera_target_entity`.
- Use the same layout for camera bounds, transition routes, and the scene's map activity integration.
- Select either one preset or a directional route configuration.

The scene adapter supplies simulation suspension and map retention to each controller.

## Presets

These entries belong inside `project_definition.resources.camera_transition`:

```lua
main = {
  pause_simulation = true,
  controller = {
    type = "cut",
    effect = { type = "fade", cover_duration = 0, reveal_duration = 0 }
  }
},

fading = {
  pause_simulation = true,
  controller = {
    type = "cut",
    effect = { type = "fade", cover_duration = 0.12, reveal_duration = 0.18 }
  }
},

sliding = {
  pause_simulation = true,
  controller = {
    type = "slide",
    duration = 0.45,
    curve = { type = "smoothstep" }
  }
}
```

All durations are in seconds.

The `cut` controller covers the screen, applies the destination framing, and reveals the scene. The built-in fade uses a black overlay.

The `slide` controller moves the camera toward the destination framing. It does not draw a screen overlay. Built-in curves are `linear` and `smoothstep`.

The current `main` preset explicitly sets both fade durations to zero. It applies the destination and completes in the same controller update without drawing an overlay. The transition releases its own suspension before the next simulation update.

A zero cover duration applies the destination immediately while preserving any positive reveal duration. A zero reveal duration completes the transition in the update that finishes covering, without an additional covered frame.

When fade durations are omitted, the registered defaults are 0.12 seconds for covering and 0.18 seconds for revealing.

## Directional routes

This entry belongs inside `project_definition.resources.map_camera_transition_routes`:

```lua
main = {
  layout = "main",
  connections = {
    east_hall = { south_hall = "sliding" },
    south_hall = { east_hall = "fading" }
  }
}
```

Each connection is directional:

- `east_hall` to `south_hall` uses `sliding`.
- `south_hall` to `east_hall` uses `fading`.
- Unlisted crossings preserve ordinary camera following when `default` is omitted.
- The optional `default` selects a preset for unlisted crossings, including entering or leaving the layout.

Without a selected preset, the camera keeps its current position and advances normal following during the crossing frame. No transition controller, overlay, or simulation suspension is created.

Destination bounds still apply through `map_camera_bounds.duration`. Equal bounds preserve continuous following; different bounds may change framing according to their configuration.

A zero-duration cut still snaps the camera to its constrained target. Use an unconfigured crossing without a default preset when continuous following is desired.

Connections reference existing map IDs and preset names. References are resolved during project loading.

These connections select presentation after a map change is detected. They do not define adjacency, exits, portals, or entity transfer rules.

## Scene selection

The current demonstration uses these fields inside `test_scene_render_configuration.main`:

```lua
render_mode = "orthographic",
world_camera_target_entity = "player",
world_camera_map_bounds = "main",
world_camera_transition = "main",
world_camera_transition_routes = "main",
```

When both transition fields are present, `world_camera_transition_routes` takes precedence.

To use one preset for every detected map change, omit `world_camera_transition_routes` and select the preset through `world_camera_transition`.

To use ordinary camera following with automatic map bounds selection, omit both transition fields.

The route resource's `default` is its fallback preset. It does not implicitly read `world_camera_transition`.

## Simulation suspension

`pause_simulation` defaults to `true`.

While suspended:

- Runtime systems and event execution stop advancing.
- Existing entity and event state is preserved.
- Simulation-driven animations pause.
- Scene drawing and transition presentation continue.
- Transient input is consumed instead of replaying after resume.
- Held input remains available when simulation resumes.

Suspension begins on the next simulation update. The simulation step that detected the crossing has already occurred.

Set `pause_simulation = false` to keep the world running during that preset. This does not override suspensions owned by other systems.

Each suspension has an independent release function. Completing or cancelling a transition releases only the suspension it acquired.

## Timing and framing

`map_camera_bounds.duration` controls ordinary changes between map bounds, including routed crossings without a selected preset.

`slide.controller.duration` controls camera travel.

`fade.cover_duration` and `fade.reveal_duration` control screen coverage.

Built-in transition controllers select destination bounds with zero bounds interpolation and apply their own presentation timing. These durations are not added together.

Maps sharing equal bounds avoid redundant bounds interpolation, but an explicitly configured fade or slide may still execute when the observed map changes.

## Active transitions

The selected preset remains active until its execution and any recovery finish.

With simulation enabled, the target may continue moving. Destination application samples its current map; a slide follows its live constrained target without restarting the configured duration.

Cancelling releases temporary requirements. On the next controller update, framing aligns with the current target without replaying the cancelled crossing.

Cancellation does not restore an earlier entity position or undo an already applied destination.

Origin and destination maps are retained during execution. Their normal activity dependencies still apply. This does not guarantee that every intermediate map along a distant slide is active.

## Customization

Custom behavior uses the existing type catalog:

- `camera_transition` registers controller types.
- `transition_effect` registers effects used by cut controllers.
- `transition_curve` registers slide interpolation curves.

A preset creates independent controller state for each camera.

Controllers used by directional routes must expose `start`, `update`, `draw`, `cancel`, `is_busy`, and `get_presented_map`.

`is_busy()` must include pending recovery. `get_presented_map()` reports the last applied destination, which may differ from the map that originally triggered the execution.

Effects used by `TransitionRunner` expose `update(dt, applied)` and optionally `draw(context)`. Their update result is `running`, `apply`, or `done`.

The runner applies the destination at most once and attempts cleanup after completion, cancellation, or failure.

## Current boundaries

- Integration is orthographic; perspective transitions require separate composition.
- Map detection samples positions and does not enumerate every intermediate crossing.
- Map retention preserves activity; it does not implement streaming or disk persistence.
- Transition presentation does not add collision rules, stairs, projectiles, or movement mechanics.
