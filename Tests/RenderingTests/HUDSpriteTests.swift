import XCTest
import RedECS
import RedHUD
import Geometry

@MainActor
class HUDSpriteTests: HUDSnapshotTestCase {
    /// hud-sprite is a 32x16 sheet: frame-0 red with a white border,
    /// frame-1 blue with a yellow border.
    func testFrameAndFullTextureSprites() throws {
        preloadResources([.init(name: "hud-sprite", type: .image)])
        setHUD {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Sprite("hud-sprite", frame: "frame-0")
                    Sprite("hud-sprite", frame: "frame-1")
                }
                Sprite("hud-sprite") // whole 32x16 sheet
            }
        }
        snapshotFrame()
    }

    /// Animation frames are selected by a game-supplied time: 0.0s falls in
    /// frame-0's 160ms window, 0.2s in frame-1's, pinned to opposite corners.
    func testAnimationFrameSelectedByTime() throws {
        preloadResources([.init(name: "hud-sprite", type: .image)])
        setHUD {
            ViewportStack {
                Pin(.topLeading) {
                    Sprite("hud-sprite", animation: "blink", time: 0)
                }
                Pin(.bottomTrailing) {
                    Sprite("hud-sprite", animation: "blink", time: 0.2)
                }
            }
        }
        snapshotFrame()
    }
}
