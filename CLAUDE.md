# RedECS — project rules

RedECS is a cross-platform (Metal + WebAssembly/WebGL) game engine. It is developed
alongside sibling repos that live next to this one and are consumed by path or by
tagged GitHub release: `../Geometry`, `../RPTrunk`, `../swift-random-dungeon-generator`,
`../swift-graphs`, and the game `../dungeon-cleaners`. These rules apply across the
whole ecosystem.

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
  - Re-record with `SNAPSHOT_TESTING_RECORD=all swift test` and review the
    changed pngs in the diff.
- Launching an app is allowed only as a does-it-crash check (e.g. `pgrep` after a
  few seconds); assert nothing visual from a live run.

## Known issues live in known-issues.md

`known-issues.md` (next to this file) is the durable record of diagnosed
issues across the ecosystem. Maintain it continuously: when an issue is
diagnosed, add an entry (where / symptom / cause); when one is fixed, move it
to the Resolved section with the fixing commit; when instructions in a session
add to or resolve an issue, update the file in the same change.

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
