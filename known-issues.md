# Known Issues — RedECS

Durable record of diagnosed issues (where / symptom / cause). Issues live in the
repo where the symptom is felt. Added from a full-engine audit, 2026-07-15. When
an issue is fixed, delete its entry outright — this file only ever holds what is
still open, no resolved-issue history or fixing commit hashes; git history is the
record of what changed and when.

## Open

### Core ECS / Store

- **`.resending` disables delta and entity-event reduction**
  Where: `Sources/RedECS/Reducer/Reducers/Resending.swift:6,17`
  Symptom: any reducer wrapped in `.resending { }` silently stops doing per-frame
  work and stops reacting to entity added/removed events.
  Cause: the `AnyReducer` it builds stubs the delta and entityEvent positions with
  `{ _,_,_ in .none }` instead of forwarding to `self.reduce`.

- **Cold `Future` re-executes work per subscribe; `zip` can double-resolve**
  Where: `Sources/RedECS/Utilities/Future.swift:11-15, 69-86, 120-131`
  Symptom: multiple subscriptions re-run the underlying load; zero subscriptions
  run nothing (see WebRenderer texture-poisoning issue below). When ≥2 zipped
  futures fail, the resolver fires once per failure, so downstream effects
  (including `GameStore` `.deferred` handling) execute multiple times.
  Cause: `subscribe` re-invokes the observer block each call; `zip` has no
  already-resolved flag. Also no thread-safety on `zip`'s captured state.

- **Effect/action cycles recurse without bound in the dispatch loop**
  Where: `Sources/RedECS/Store/GameStore.swift:43-60`
  Symptom: a reducer that (transitively) re-emits the action it handles crashes
  with stack overflow.
  Cause: `handleEffect` → `sendAction` → `handleEffect` is direct recursion; no
  queue/trampoline or depth cap.

- **`newEntityId()` is collision-prone and nondeterministic**
  Where: `Sources/RedECS/Entity/GameEntity.swift:5`
  Symptom: possible silent state corruption on ID collision (duplicate-entity
  check is assert-only, `EntityRepository.swift:31`); replay/lockstep determinism
  impossible; weaker on wasm32 where `Int` is 32-bit.
  Cause: two `Int.random` values concatenated without a separator (so distinct
  pairs can collide textually), system RNG. Known TODO in code.

- **Unregistered component types leak on entity destruction (release builds)**
  Where: `Sources/RedECS/Store/GameStore.swift:75-77` vs `96-98`
  Symptom: components of unregistered types survive entity removal forever.
  Cause: registration check is assert-only, but the destroy sweep iterates only
  `registeredComponentTypes`. Related: component ids are `String(describing: C.self)`
  (`AnyComponent.swift:8`) — same-named types in different modules collide.

- **`awaitingEffects` grows without bound**
  Where: `Sources/RedECS/Store/GameStore.swift:57-58`
  Symptom: memory growth and per-action O(pending × outstanding) scan cost when
  awaited actions never arrive (entity died, scene changed).
  Cause: `waitFor` effects have no timeout/cancellation/cap.

- **`waitFor` continuations run before the triggering action is reduced**
  Where: `Sources/RedECS/Store/GameStore.swift:28-40`
  Symptom: a continuation waiting on action A observes state that A's reducer has
  not yet updated.
  Cause: `completedEffects.forEach(handleEffect)` executes before
  `reducer.reduce(state:action:)`.

### Rendering (cross-platform)

- **Sprite culling tests only the transform origin**
  Where: `Sources/RedECS/Rendering/Sprite/SpriteComponent.swift:241-244`
  Symptom: a large `.texture` sprite pops out of view while still partially
  on screen.
  Cause: the cull compares the transform's projected origin against a fixed
  1.05 NDC threshold rather than the sprite's projected bounds.

- **Animation frame-duration units are inconsistent (ms vs s)**
  Where: `Sources/RedECS/Rendering/Sprite/SpriteComponent.swift:15` (`/ 1000`,
  ms) vs `SpriteAnimationDictionary.swift:33` (`?? 0.16` fallback, seconds-flavored)
  Symptom: frames without an explicit duration flash by (0.16 ms effective).
  Cause: consumer divides by 1000; the default was authored in seconds.
  Related: frame timer resets to 0 dropping overshoot and advances ≤1 frame per
  tick (`SpriteComponent.swift:106-107`) — animations run slower than authored.

- **Camera selection uses an invalid sort comparator**
  Where: `Sources/RedECS/Rendering/RenderableComponent.swift:63`
  Symptom: with >1 camera, the chosen camera is nondeterministic frame-to-frame
  (and the comparator violates strict weak ordering).
  Cause: `sorted(by: { $1.isPrimaryCamera ? false : true })` never inspects `$0`,
  over unordered `Dictionary.values`. Also `CameraComponent.offset` is declared
  but never applied (`CameraComponent.swift:7`).

- **BitmapFont parser traps on ordinary .fnt files**
  Where: `Sources/RedECS/Rendering/Label/BitmapFont.swift:27-32`
  Symptom: crash loading a font whose quoted values contain spaces (e.g.
  `face="Arial Black"`), tokens without `=`, or whitespace-only lines.
  Cause: naive space-split then `parts[1]` with no bounds check.
  Related: glyph layout ignores `xoffset` and kerning; `\n` collapses to one line
  (`SpriteComponent.swift:224-231`); character map keys on the nonstandard
  `letter=` attribute (`BitmapFont.swift:55-57`).

- **Opacity dropped for shape render groups**
  Where: `Sources/RedECS/Rendering/Sprite/SpriteComponent.swift:174-182`
  Symptom: `sprite.opacity` has no effect on `.shape` sprites.
  Cause: `RenderGroup` built without the `opacity:` argument in that path.

- **Atlas `rotated`/`trimmed` frames render wrong**
  Where: `Sources/RedECS/Rendering/Sprite/SpriteComponent.swift:287-292`
  Symptom: atlases packed with rotation/trim enabled render sideways/offset.
  Cause: UV rect uses `frameInfo.frame` only; `rotated`/`trimmed`/
  `spriteSourceSize` are decoded but never consulted (`TextureMap.swift:17-20`).

- **Hostile/degenerate animation data traps**
  Where: `Sources/RedECS/Rendering/Sprite/SpriteAnimationDictionary.swift:30-32`
  (`frames[(from...to)]` unvalidated range), `SpriteComponent.swift:88,15`
  (empty `frames` array).
  Symptom: crash on malformed atlas JSON or empty animation.
  Cause: no validation of decoded indices/ranges.

### Gameplay components (RedECSBasicComponents)

- **`RepeatOperation.times(n)` completion math is wrong; can trap**
  Where: `Sources/RedECSBasicComponents/Operation/OperationTypes/RepeatOperation.swift:46`
  Symptom: `.times(1)` completes on the first tick; `.times(n≥2)` completes after
  ~1 iteration; `delta == 0` on the first tick traps (`Int(0/0)` = Int(NaN)).
  Cause: `Int(totalTime / currentTime) >= count` divides elapsed total by
  time-in-current-iteration instead of tracking completed iterations.

- **Move/Rotate/Opacity operations overshoot and divide by zero**
  Where: `MoveOperation.swift:36-39`, `RotateOperation.swift:48-51`,
  `OpacityOperation.swift:48-50`
  Symptom: `.to` tweens land past their target by up to one frame's fraction;
  `duration: 0` produces inf/NaN transform values.
  Cause: `percentage = delta / duration` unclamped to remaining time.
  Note: `ScaleOperation.swift:41-43` already contains the correct clamped
  implementation — port it to the other three.

- **Pathing can oscillate forever at a waypoint**
  Where: `Sources/RedECSBasicComponents/Pathing/PathingReducer.swift:42,50-53`
  Symptom: when per-frame travel exceeds `allowableProximityVariance`, the entity
  crosses the waypoint each frame, never satisfies the arrival test, and
  `.pathingComplete` never fires; `allowableProximityVariance = 0` is
  unsatisfiable (strict `<`). Diagonal movement is also up to 41% faster than
  axis-aligned (Chebyshev normalization of the steering vector).
  Cause: no step clamping / arrival slowdown; `<` instead of `<=`; per-component
  division by max component instead of Euclidean normalization.

- **Animation/sequence timing drops frame-time remainders**
  Where: `SequenceOperation.swift:30-33`, `AnimateOperation.swift:39-53`,
  `TimingOperation.swift:20,30`
  Symptom: sequences of instant ops take one frame each; animations run slower
  than authored, frame-rate dependently; easing overshoots on the final frame;
  `TimingOperation` over an instant or `.forever` inner op breaks (NaN percent /
  immediate completion).
  Cause: completed child ops don't pass unused delta onward; timers reset to 0
  instead of subtracting; ease input unclamped; duration algebra inconsistent
  across combinators.

- **`InteractionWhenNearbyReducer` fires every frame while in range**
  Where: `Sources/RedECSBasicComponents/InteractionComponent.swift:77-79`
  Symptom: non-idempotent actions (pickup, dialogue, sfx) dispatch ~60×/s per
  in-range triggerer.
  Cause: no edge-triggering/enter-leave state. The `.selection` interaction type
  has no reducer handling anywhere (dead case).

- **Resource-load failure asserts in debug, hangs silently in release**
  Where: `Sources/RedECSBasicComponents/ResourceLoading/ResourceLoadingReducer.swift:29`
  Symptom: a missing asset crashes debug; in release nothing awaiting
  `.loadComplete` ever proceeds.
  Cause: `.loadingError` handler is `assertionFailure` + print, with no recovery
  effect.

### Platform: Web (RedECSWebSupport)

- **Discarded cold Future permanently poisons texture loading**
  Where: `Sources/RedECSWebSupport/WebRenderer.swift:91` +
  `WebResourceManager.swift:32-38`
  Symptom: a texture first referenced by a render group before being preloaded
  never loads and can never be loaded (stuck `.loading`).
  Cause: `startTextureLoadIfNeeded` marks `.loading` eagerly but returns a cold
  Future that the caller discards — nothing subscribes, the fetch never starts,
  and the `textures[id] == nil` guard blocks all retries.

- **Image load has no `onerror`; missing asset hangs preload forever**
  Where: `Sources/RedECSWebSupport/WebResourceManager.swift:114-129`
  Symptom: one misnamed PNG and the game silently never starts (preload `.zip`
  never completes); a 404 also isn't detected (`response.ok` unchecked).
  Cause: only `image.onload` is wired; no error path resolves the Future.

- **WebGL objects created per group per frame, never deleted**
  Where: `Sources/RedECSWebSupport/WebGL/Draw2DProgram.swift:87,104,124,129,146`
  Symptom: GPU memory grows until the browser kills the WebGL context (context
  loss is also unhandled).
  Cause: `createBuffer`×3 + `createTexture` + full `texImage2D` re-upload inside
  the per-group draw path; no `deleteBuffer`/`deleteTexture` anywhere.

- **Draw error path calls `fatalError()`**
  Where: `Sources/RedECSWebSupport/WebRenderer.swift:95-98`
  Symptom: a single recoverable GL error kills the wasm instance.

- **Per-frame `JSClosure` allocations never released; input listeners can't be removed**
  Where: `Sources/RedECSWebSupport/WebBrowserWindow.swift:44-127`
  Symptom: closure leak per frame (rAF) and per listener; calling
  `addAllInputListeners()` twice double-dispatches all input.
  Cause: fire-and-forget `JSClosure` with no retention/release management.

- **Touch coordinates skip the canvas-offset correction mouse events get**
  Where: `Sources/RedECSWebSupport/WebBrowserWindow.swift:84-86`
  Symptom: taps land offset from the touch point when the canvas isn't at the
  document origin.
  Cause: raw `pageX/pageY` used instead of `position(for:in:)`.

- **Font cache checked under filename, stored under face name**
  Where: `Sources/RedECSWebSupport/WebResourceManager.swift:197,236`
  Symptom: fonts re-fetched and re-parsed on every load when filename ≠ face.

- **`WebHUDRenderingReducer` is entirely dead code**
  Where: `Sources/RedECSWebSupport/WebHUDRenderingReducer.swift`
  Symptom: file is one large block comment referencing a removed PIXI-based API;
  web HUD input/rendering doesn't exist despite the type being shipped.

### Platform: Metal (RedECSAppleSupport)

- **`fatalError` on routinely-nil MTKView state**
  Where: `Sources/RedECSAppleSupport/MetalRenderer.swift:143,149,163,252`
  Symptom: minimizing/occluding the window (drawable pool exhaustion) crashes
  the app instead of skipping the frame.
  Cause: `currentRenderPassDescriptor`/`currentDrawable`/command buffer nils are
  treated as fatal.

- **Missing texture leaves a stale or unbound fragment texture + NaN texcoords**
  Where: `Sources/RedECSAppleSupport/MetalRenderer.swift:203-208,219-226`,
  `Shaders.metal:78`
  Symptom: groups whose texture isn't loaded sample the previous group's texture
  (or an unbound one), and `texSize = (0,0)` divides to NaN texcoords. Unlike
  the web path, nothing triggers a load for missing textures.
  Cause: nil-texture branch is a commented-out print; no fallback binding.

- **Shaders make alpha binary; blending mismatched with premultiplied content**
  Where: `Shaders.metal:98-101` and `Draw2DProgram.swift:264-269` (same logic)
  Symptom: anti-aliased sprite edges render as hard opaque fringes; texture tint
  RGB ignored; MTKTextureLoader premultiplied content blended with
  `.sourceAlpha` double-darkens edges.
  Cause: `if (alpha == 0) ... else alpha = group opacity` discards partial alpha.

- **One draw call per triangle + `waitUntilCompleted` per frame**
  Where: `MetalRenderer.swift:316-327,339`
  Symptom: draw-call count equals triangle count (chunked `setVertexBytes` of 3
  vertices) and the CPU blocks until the GPU finishes each frame — no
  pipelining; performance ceiling is very low.
  Cause: 4KB `setVertexBytes` limit worked around by chunking instead of a
  shared/ring `MTLBuffer`; unnecessary full-frame wait.

- **Failed texture loads are unretryable (both platforms)**
  Where: `MetalResourceManager.swift:91,109`; `WebResourceManager.swift:32,50`
  Symptom: a transient load failure permanently loses the texture.
  Cause: `.failedToLoad` state satisfies the `!= nil` short-circuit guard forever.

### Performance

Allocation and copy costs on the per-frame path. None of these are measured — there
is no benchmark target — so treat the ordering as untested. Added 2026-07-31.

- **`Matrix3` is heap-backed, so every transform costs 4+ allocations**
  Where: `Geometry` 0.0.5, `Sources/GeometryAlgorithms/Matrix3/Matrix3.swift:5`;
  felt at `Sources/RedECS/Rendering/Transform/TransformComponent.swift:35-41` and
  `Sources/RedECS/Rendering/RenderableComponent.swift:106,111,118`
  Symptom: allocation churn scaling with entity count × tree depth, on every frame.
  Cause: `Matrix3` stores `values: [Double]` and every operation returns a new matrix
  built from an array literal. `TransformComponent.matrix()` chains `.identity →
  translatedBy → rotatedBy → scaledBy` = 4 arrays per call, and the render walk calls
  it once per node plus two `.multiply`s per node per renderable type. Fix is 9 stored
  `Double`s in the Geometry package (needs a coordinated release).

- **The render walk copies whole game state per node, per renderable type**
  Where: `Sources/RedECS/Rendering/RenderableComponent.swift:18,26-28,102`
  Symptom: per-frame cost scales with (tree nodes × registered renderable types) even
  for entities that have none of those components.
  Cause: `RenderableComponentType.getRenderComponent` is `(EntityId, State) -> …`,
  taking `State` **by value**, so each probe copies the state struct (retaining every
  component dictionary) and boxes any match into a `RenderableComponent` existential.
  No query or archetype index exists to skip non-matching nodes.

- **`OperationReducer` materializes two whole component stores per operation**
  Where: `Sources/RedECS/Operation/OperationReducer.swift:41,43`; bridges at
  `Sources/RedECS/Operation/OperationComponent.swift:13-27,29-41`
  Symptom: the most expensive line on the frame path; cost is
  (entities with operations × operations each) × size of `transform` + `sprite`.
  Cause: `basicOperationComponentState` is a *computed* property whose getter rebuilds
  a context from the component dictionaries and whose setter writes them all back.
  Passing `&state.basicOperationComponentState` inside the nested loop forces a full
  get-modify-set each iteration, and the returned `GameEffect` stores the same key
  path (`:43`) so the copy is replayed when the effect is applied. `operationContext`
  (`:13-27`) has the same shape.

- **`HUDNode.flattenedGroups()` re-maps the accumulated group array per tree level**
  Where: `Sources/RedHUD/HUDNode.swift:59-75`
  Symptom: HUD render cost grows super-linearly with nesting depth; deep stacks with
  transform/clip/opacity modifiers are worst.
  Cause: the recursion builds `groups + children.flatMap { … .map { reparented } }`,
  then applies up to three further full-array `.map` passes (transform, clip, opacity)
  at *every* level, so a group near the leaves is copied once per ancestor.

- **The HUD view tree is rebuilt and re-resolved from scratch every frame**
  Where: `Sources/RedHUD/HUDRenderingReducer.swift:48,60,68-78`
  Symptom: steady-state allocation for a HUD that hasn't changed.
  Cause: inherent to the immediate-mode design — `content(state)` allocates the view
  tree, `resolve` allocates the `HUDNode` tree, `flattenedGroups()` allocates the
  group array, and `.map` allocates it again to apply z-index. There is no
  change-detection or retained-tree fast path when state and viewport are unchanged.

- **Per-frame cache pruning allocates fresh dictionaries**
  Where: `Sources/RedHUD/Animation/AnimationSlots.swift:32-33`,
  `Sources/RedHUD/HUDCache.swift:57`
  Symptom: three dictionary allocations per frame regardless of whether anything
  changed.
  Cause: `endAnimationFrame`/`endScrollFrame` prune with `filter`, which builds a new
  dictionary. In-place `removeAll(where:)`-style pruning would avoid it. Related: the
  slot keys are `[IdentityToken]` arrays (`AnimationKey.path`, `scrollSlots`), so each
  lookup hashes an array.

- **The per-frame reducer tree is entirely dynamically dispatched**
  Where: `Sources/RedECS/Reducer/Reducers/AnyReducer.swift:3-5`
  Symptom: no inlining across reducer composition on the frame path.
  Cause: `AnyReducer` stores its three `reduce` entry points as closures, so every
  node in a composed tree is an opaque call.

- **`GameState.modify` is dead code, and the slowest available mutation pattern**
  Where: `Sources/RedECS/GameState.swift:5-33`
  Symptom: none today — it has no call sites anywhere in `Sources/` or `Tests/`.
  Cause: unconditional copy-out/copy-back of the whole component, versus `Dictionary`'s
  in-place `state.X[id]?.field = …`. It also `assertionFailure`s on a missing
  component. Either delete it or reimplement it in terms of the in-place subscript
  before anything starts calling it.

- **`EntityId` is `String`, so every component lookup hashes a string**
  Where: `Sources/RedECS/Entity/GameEntity.swift:3`
  Symptom: string hashing on every component dictionary access, many times per entity
  per frame; every component also carries a heap-allocated `String` payload.
  Cause: `typealias EntityId = String`. An integer handle would likely be the largest
  structural win available, but it is a breaking change for downstream games and
  interacts with the `Codable` save format and with `newEntityId()` above.
