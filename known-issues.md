# Known Issues

Diagnosed issues in the RedECS engine. An issue lives with the repo where its
symptom is felt; when fixed, move it to Resolved with the fixing commit.

## Open

(none)

## Resolved

### Text snapshots differ between Xcode and `swift test`

- **Where:** Tests/RenderingTests (BitmapFontTests, HUDTextTests) — any
  snapshot that samples a texture (bitmap-font glyphs); solid-color
  snapshots were unaffected.
- **Symptom:** Snapshot references recorded via `swift test` fail when the
  suite runs inside Xcode (and vice versa), with small deltas (max channel
  delta ~18/255, ~2% of pixels) confined to anti-aliased glyph edges.
- **Cause:** `MetalResourceManager.loadTexture` preferred the asset-catalog
  lookup (`MTKTextureLoader.newTexture(name:)`) over the loose file. Asset
  catalogs are only compiled by Xcode, and its catalog compiler
  re-encodes/color-manages the image — so the pt-mono atlas sampled under
  Xcode had subtly different texels than the raw png the CLI fallback
  loads, and the snapshot strategy compares at exact precision. (The
  engine's other Xcode-only build feature, metal shader precompilation,
  was the same class of divergence waiting to happen.)
- **Fix:** two determinism changes so Xcode and the CLI share one
  rendering path: `loadTexture` now prefers the loose image file (raw
  bytes, identical in both environments) with the asset catalog demoted to
  fallback; and `Shaders.metal` became a `.copy` resource so Xcode bundles
  the source verbatim instead of precompiling a metallib, leaving the
  runtime shader compile as the single path. Verified: full RenderingTests
  suite passes via both `swift test` and `xcodebuild test` against the
  same references.
