import XCTest
import TiledInterpreter
@testable import RedECS

/// Frame durations are milliseconds everywhere they are consumed
/// (`SpriteAnimation.needsNextFrame` and RedHUD's `frame(at:)` both divide by
/// 1000), so the fallback for an atlas without per-frame durations must be in
/// milliseconds too.
final class SpriteAnimationDictionaryTests: XCTestCase {
    private func textureMap(durations: [Double?]) -> TextureMap {
        TextureMap(
            frames: durations.enumerated().map { index, duration in
                .init(
                    filename: "frame-\(index)",
                    frame: .init(x: Double(index) * 16, y: 0, w: 16, h: 16),
                    rotated: false, trimmed: false,
                    spriteSourceSize: .init(x: 0, y: 0, w: 16, h: 16),
                    sourceSize: .init(w: 16, h: 16),
                    duration: duration
                )
            },
            meta: .init(
                image: nil,
                size: .init(w: Double(16 * durations.count), h: 16),
                format: nil,
                frameTags: [
                    .init(name: "blink", from: 0, to: durations.count - 1, direction: "forward")
                ]
            )
        )
    }

    func testMissingFrameDurationFallsBackToAPlayableMillisecondValue() throws {
        let dict = try SpriteAnimationDictionary(name: "atlas", textureMap: textureMap(durations: [nil, nil]))
        let animation = try XCTUnwrap(dict["blink"])
        XCTAssertEqual(animation.frames.map(\.duration), [160, 160])

        var sprite = SpriteComponent(
            entity: "e",
            type: .texture(TextureReference(textureId: "atlas", frameId: "frame-0"))
        )
        sprite.runAnimation(animation, animationId: nil, repeatsForever: true)
        // A 60fps tick is well inside the first frame; the old 0.16 fallback
        // advanced on every one of them.
        XCTAssertNil(sprite.applyDelta(1.0 / 60))
        XCTAssertEqual(sprite.animation?.currentFrame, 0)
    }

    func testExplicitFrameDurationsArePreserved() throws {
        let dict = try SpriteAnimationDictionary(name: "atlas", textureMap: textureMap(durations: [2250, 300]))
        let animation = try XCTUnwrap(dict["blink"])
        XCTAssertEqual(animation.frames.map(\.duration), [2250, 300])
    }
}
