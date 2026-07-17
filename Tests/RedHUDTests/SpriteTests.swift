import XCTest
import Geometry
import RedECS
@testable import RedHUD

final class SpriteTests: XCTestCase {
    // A 32x16 sheet with two 16x16 frames tagged as the "blink" animation,
    // 160ms per frame.
    private func makeContext() -> HUDRenderContext {
        let json = """
        {
          "frames": [
            {
              "filename": "frame-0",
              "frame": {"x": 0, "y": 0, "w": 16, "h": 16},
              "rotated": false, "trimmed": false,
              "spriteSourceSize": {"x": 0, "y": 0, "w": 16, "h": 16},
              "sourceSize": {"w": 16, "h": 16},
              "duration": 160
            },
            {
              "filename": "frame-1",
              "frame": {"x": 16, "y": 0, "w": 16, "h": 16},
              "rotated": false, "trimmed": false,
              "spriteSourceSize": {"x": 0, "y": 0, "w": 16, "h": 16},
              "sourceSize": {"w": 16, "h": 16},
              "duration": 160
            }
          ],
          "meta": {
            "size": {"w": 32, "h": 16},
            "frameTags": [
              {"name": "blink", "from": 0, "to": 1, "direction": "forward"}
            ]
          }
        }
        """
        let map = try! JSONDecoder().decode(TextureMap.self, from: Data(json.utf8))
        let resourceManager = FakeResourceManager()
        resourceManager.textures["hud-sprite"] = .loaded(map)
        return HUDRenderContext(resourceManager: resourceManager)
    }

    func testFrameSpriteSizesToFrame() {
        let context = makeContext()
        let size = Sprite("hud-sprite", frame: "frame-1")
            .size(proposed: ProposedSize(width: 999, height: 999), context: context)
        XCTAssertEqual(size, Size(width: 16, height: 16))
    }

    func testFullTextureSpriteSizesToPage() {
        let context = makeContext()
        let size = Sprite("hud-sprite")
            .size(proposed: ProposedSize(), context: context)
        XCTAssertEqual(size, Size(width: 32, height: 16))
    }

    func testMissingTextureOccupiesNoSpace() {
        let context = makeContext()
        XCTAssertEqual(
            Sprite("nope").size(proposed: ProposedSize(), context: context),
            .zero
        )
        XCTAssertTrue(Sprite("nope").render(context: context, size: .zero).isEmpty)
        XCTAssertEqual(
            Sprite("hud-sprite", frame: "missing-frame")
                .size(proposed: ProposedSize(), context: context),
            .zero
        )
    }

    func testRenderEmitsTexturedQuadInLocalYDownSpace() {
        let context = makeContext()
        let sprite = Sprite("hud-sprite", frame: "frame-0")
        let groups = sprite.render(context: context, size: Size(width: 16, height: 16))
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].textureId, "hud-sprite")
        XCTAssertEqual(groups[0].triangles.count, 2)
        XCTAssertNotNil(groups[0].triangles[0].textureTriangle)
        let corners = groups[0].triangles
            .flatMap { [$0.triangle.a, $0.triangle.b, $0.triangle.c] }
            .map { $0.multiplyingMatrix(groups[0].transformMatrix) }
        XCTAssertEqual(corners.map(\.x).min(), 0)
        XCTAssertEqual(corners.map(\.x).max(), 16)
        XCTAssertEqual(corners.map(\.y).min(), 0)
        XCTAssertEqual(corners.map(\.y).max(), 16)
    }

    func testAnimationTimeSelectsAndLoopsFrames() {
        let context = makeContext()
        func frameRectX(at time: Double) -> Double? {
            let sprite = Sprite("hud-sprite", animation: "blink", time: time)
            let groups = sprite.render(context: context, size: Size(width: 16, height: 16))
            return groups.first?.triangles
                .compactMap { $0.textureTriangle }
                .flatMap { [$0.a.x, $0.b.x, $0.c.x] }
                .min()
        }
        XCTAssertEqual(frameRectX(at: 0), 0)      // frame-0 (0.00-0.16s)
        XCTAssertEqual(frameRectX(at: 0.2), 16)   // frame-1 (0.16-0.32s)
        XCTAssertEqual(frameRectX(at: 0.33), 0)   // wrapped back to frame-0
        XCTAssertEqual(frameRectX(at: -0.1), 16)  // negative time wraps too
    }

    func testUnknownAnimationOccupiesNoSpace() {
        let context = makeContext()
        XCTAssertEqual(
            Sprite("hud-sprite", animation: "nope", time: 0)
                .size(proposed: ProposedSize(), context: context),
            .zero
        )
    }
}
