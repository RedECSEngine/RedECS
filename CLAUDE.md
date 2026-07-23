# RedECS — project rules

RedECS is a cross-platform (Metal + WebAssembly/WebGL) game engine. It is developed
alongside sibling repos that live next to this one and are consumed by path or by
tagged GitHub release: `../Geometry`, `../RPTrunk`, `../swift-random-dungeon-generator`,
`../swift-graphs`, and the game `../dungeon-cleaners`. These rules apply across the
whole ecosystem.

## Never edit downstream consumers without permission

When modifying this library, never assume you can edit a downstream project that
depends on it via a local path reference — not even to test or verify your
changes, and not even for a mechanical rename. Those repos are separate, often
hold the developer's own uncommitted work, and a rename here breaking their build
is expected fallout for them to resolve. Make the change here, flag the downstream
breakage, and explicitly ask for permission (or wait until you are prompted)
before touching another repo.

## API ergonomics come first

RedECS is shared across many kinds of projects, so its public surface must be
simple, consistent, and free of gotchas — a caller should be able to reach for
the obvious thing and have it work, without knowing hidden preconditions.

- **Consistency over cleverness.** Similar concepts should look and behave
  alike: same argument shapes, same defaults, same naming patterns. When two
  APIs do parallel things (e.g. the stack family, the render reducers), justify
  any divergence — an inconsistency the caller has to memorize is a bug.
- **No silent gotchas.** Avoid APIs that compile and run but do the wrong thing
  when a hidden precondition isn't met (wrong reducer order, missing camera,
  a field set directly instead of through its intended mutator). Prefer designs
  that make misuse impossible; where that's impractical, fail loudly (assert) or
  document the precondition at the call site, never leave it to silently misrender.
- **One obvious way in.** If there's a correct path to do something, don't also
  leave an incorrect-looking shortcut exposed. Prefer the pit of success.
- **Defaults should fit the common case.** A default a caller must override to
  get sensible behavior is a gotcha; pick the value most projects actually want.
- Weigh ergonomics explicitly when adding or reviewing public API, and surface
  trade-offs rather than quietly picking convenience over consistency.

## Foundation is banned in cross-platform code

- Core/cross-platform modules do not `import Foundation`, and new code must not
  introduce it either. Keeping the core Foundation-free keeps wasm binaries lean
  and the engine portable.
- If something genuinely needs Foundation-level functionality in the future,
  `FoundationEssentials` (from swift-foundation) is the acceptable fallback —
  but it is not used anywhere yet; reach for it only with good justification.
- Platform-support layers are the exception where platform frameworks are
  unavoidable (e.g. `RedECSAppleSupport` uses MetalKit/Foundation; `RedECSWebSupport`
  uses JavaScriptKit).
- Watch out for Swift 5 language mode's leaky member visibility: a single
  `import Foundation` in one file makes Foundation extension members (like
  `String.components(separatedBy:)`) resolve in *every* file of the module on
  Apple platforms — the wasm build is what surfaces the violation. Verify
  Foundation-free claims with a wasm build, not a macOS build.

## Keep dependencies minimal

Prefer small in-house solutions serving immediate needs over external packages
adopted for posterity. RPTrunk is intentionally dependency-free: its condition
DSL uses a hand-rolled recursive-descent parser with an in-house parser-printer
protocol (`ConditionParserPrinter`) rather than swift-parsing, which hard-imports
Foundation and had repeated 0.x API churn. Before adding any dependency, check
what fraction of it will actually be used and what it links transitively.

## Verification: snapshot tests, never screen capture

- Never capture the user's screen (`screencapture`, activating windows to grab
  images, etc.) to verify visual behavior.
- Visual verification is done with snapshot tests (swift-snapshot-testing):
  - Engine rendering: `Tests/RenderingTests` (Metal, via the `MTKView` strategy).
  - Full game state: `dungeon-cleaners/DungeonCleanersKit/Tests/GameSnapshotTests`
    boots the real game and snapshots tiles + player + objects in one frame.
  - **Never bulk re-record.** `SNAPSHOT_TESTING_RECORD=all` (and deleting a
    `__Snapshots__` dir wholesale) redefines whatever the code currently emits
    as correct, so a regression in that run silently becomes the new baseline
    and can never fail again. Run the tests, read each failure on its own, work
    out what changed and why, confirm the change is intended, and only then
    re-record that one reference (delete that specific png and re-run). Review
    every diff image.
- Launching an app is allowed only as a does-it-crash check (e.g. `pgrep` after a
  few seconds); assert nothing visual from a live run.

## Known issues live in each repo's known-issues.md

Each repo keeps a `known-issues.md` at its root as the durable record of its
diagnosed issues — an issue lives with the repo where its *symptom* is felt,
even when the cause is in a dependency (note the cross-repo location in the
entry). Game issues live in `../dungeon-cleaners/known-issues.md`. Maintain
these continuously: when an issue is diagnosed, add an entry (where / symptom
/ cause); when one is fixed, move it to the Resolved section with the fixing
commit; when instructions in a session add to or resolve an issue, update the
file in the same change.

## Git workflow

- When working on a branch, commit often with incremental work. History can
  always be rewritten/squashed before merging, so prefer small checkpoint
  commits over large uncommitted working trees.

## Toolchain facts

- Swift 6.2 is the only supported floor, everywhere in the ecosystem. All RedECS
  and DungeonCleanersKit targets build in the Swift 6 language mode (RPTrunk core
  is still Swift 5 language mode under tools 6.2).
- Tests must pass from the command line (`swift test`), not just Xcode. The engine
  has runtime fallbacks for the two Xcode-only build features (metal shader
  compilation, asset catalogs); keep CLI compatibility in mind when adding
  resources.
- WebAssembly builds need the swift.org toolchain (via swiftly) paired with the
  exactly-matching SwiftWasm SDK version:
  `swiftly run swift build --swift-sdk 6.2-RELEASE-wasm32-unknown-wasip1 --target RedECSWebSupport +6.2.0`.
  Only web products/targets cross-compile; `RedECSAppleSupport` cannot build for wasm.
