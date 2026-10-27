# Actrune changelog

## 0.6.0 — 2026-10-27

### Added

- Optional route defaults, allowing continuous camera following on unconfigured map crossings without cuts or simulation suspension.
- Declarative orthographic camera bounds per map, with shared framing and global fallback.
- Immediate and timed bounds changes without recreating the camera.
- A generic transition runner with destination application, cancellation, and cleanup.
- Reusable camera transition presets with configurable simulation suspension.
- Camera cuts with a screen fade and camera slides with configurable duration.
- Extensible transition controllers, screen effects, and interpolation curves.
- Directional map connections selecting different presets for each travel direction.
- Temporary map activity requirements preserving origin and destination visuals during transitions.
- LuaCATS documentation for camera bounds, transition execution, and routing.

### Changed

- Simulation can pause while scene drawing and transition presentation continue.
- Simulation suspension preserves entity state and event execution state.
- Independent suspension owners release only their own pause.
- Transient input is consumed during suspension instead of replaying after resume.
- The demonstration uses a slide from east_hall to south_hall and a fade on the return path.

### Fixed

- Preserved camera smoothing during continuous map crossings instead of snapping to the target, including horizontal loops.
- Fades with zero reveal duration now complete as soon as covering finishes, avoiding an extra covered frame and suspended simulation update.

### Current limitations

- Camera transition integration currently targets orthographic rendering.
- Connections select presentation for detected map changes; they do not create exits or transfer entities.
- Map changes remain based on sampled positions.
- Retaining transition endpoints does not guarantee activity across every intermediate map of a distant slide.

## 0.5.0 — 2026-09-16

### Added

- Static entity visuals integrated into the runtime without requiring an update lifecycle.
- Declarative spatial levels and entity elevation on the Z axis.
- Vertical collision and interaction filtering, including configurable height bypass.
- Independent entity and ground elevation in projections, with camera elevation tracking.
- Configurable horizontal and vertical map loops, periodic spatial queries, repeated visuals, and continuous camera tracking.
- Declarative resident maps, shared actors, neighbors, and map entry/exit events.
- Map activity management that preserves entity instances and runtime state across transitions.
- Event-page map requirements that keep dependencies active until execution finishes.
- A three-map demonstration covering transitions, persistent elevation, and activity changes.
- Expanded LuaCATS documentation for spatial, entity, control, and map APIs.

### Changed

- Generalized entity visual collections and configuration.
- Inactive map content now pauses controls, animation, and physics, and is excluded from spatial queries and visual collection.
- Event map dependencies are synchronized before queued commands execute.

### Current limitations

- Inactive maps remain loaded in memory. State preservation applies to the current session; disk persistence and map unloading are not included.
- Periodic logical queries and rendering do not provide Box2D wrapping or physical contacts across opposite map edges.
- Map transitions are detected from sampled positions. Intermediate maps crossed between samples are not enumerated.
- Event callbacks must declare additional map dependencies through `required_maps`; arbitrary entity access does not infer them.

## 0.4.0 — 2026-09-06

### Added

- Declarative image animation tracks and synchronized track sets sharing a common timing clip.
- Reusable directional animation templates configured through project resources.
- Declarative entity visual bindings and ordered binding sequences.
- Animated entity visual instances with independent playback state.
- Configurable animated entity visual systems integrated with `ProjectRuntime`.
- Composable billboard sources with global projected depth sorting.
- Project resources for camera settings, projection parameters, capture dimensions, and independent camera targets.

### Changed

- Moved animated visual creation and updates out of the test scene renderer.
- Separated runtime entity visuals from their billboard adaptation.
- Injected physics and event diagnostics through the renderer composition factory.
- Extracted procedural ball animation and projected debug visuals into dedicated project sources.

## 0.3.0 — 2026-09-01

### Added

- Composable translation and rotation controls with continuous and stepped behavior.
- Configurable input axes, direction policies, movement amounts, and action application policies.
- Spatial grid contexts resolved from areas, allowing contextual grid and free movement.
- Polygon sweep queries and contact information for collision-aware movement.
- A Box2D physics backend with entity-derived bodies, declarative physical materials, and complex static boundaries.
- Declarative entity, event, and resource loading with project definition validation.
- Extensible project type catalogs and resource factories with provider-scoped registration.
- Configurable runtime systems and project runtime orchestration.
- 2D cameras with coordinate conversion, configurable follow policies, smoothing, rotation control, and bounds.
- Ordered render layers, nested groups, affine transformations, offscreen canvases, and shader presentation.
- World-space perspective plane projection with projection and unprojection, supporting Mode 7-style presentation.
- Depth-sorted billboards with directional images and reusable visual transformations.
- Rendering-independent animation clips and players with uniform or variable frame timing.
- Image assets, image regions, resource sequences, and synchronized image animation tracks.
- Lazy resource dependency resolution, circular dependency detection, and declarative reference validation.

### Changed

- Separated project definitions, runtime composition, and test scene rendering from bootstrap code.
- Separated input mapping from control intent and movement execution.
- Separated event callback bindings from declarative project capabilities.
- Separated animation playback state from billboard visual representation.

### Fixed

- Normalized diagonal movement.
- Improved polygon movement at corners to prevent sticking.

## 0.2.0 — 2026-08-12

### Added

- Spatial entities with position, rotation, and scale transforms.
- Multiple named polygon shapes per entity, transformed into world space.
- World entity management and spatial queries for point containment and polygon overlap.
- Entity-associated events with point-based, shape-based, and directional area triggers.
- Configurable single and parallel event execution modes.
- Keyboard action bindings with held, pressed, and released states.
- Reusable spatial action configuration exposed through the runtime API.

### Fixed

- Used shape overlap queries for spatial event discovery.

## 0.1.0 — 2026-08-09

### Added

- Initial Actrune runtime core.
- Event definitions with conditional pages and configurable triggers.
- Independent event runners with sequential command execution.
- Call and wait commands with shared execution context.
- Event scheduling coordinated by the runtime update loop.
