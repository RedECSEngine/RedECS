import XCTest
import RedECS
import RedHUD
import Geometry

@MainActor
class HUDAnimationTests: HUDSnapshotTestCase {
    /// Three frames of a linear scale-up from 0.5x to 1.5x over one second:
    /// the install frame shows the start value, then deltas advance the
    /// slot deterministically to the midpoint and the settled end.
    func testScaleUpTimeline() throws {
        setHUD {
            Rectangle()
                .frame(width: 100, height: 100)
                .foregroundColor(.red)
                .scaleEffect(from: 0.5, to: 1.5)
                .animated(duration: 1, timing: .linear, on: .appear)
        }
        snapshotFrame(named: "start")               // install → 50x50
        snapshotFrame(named: "middle", delta: 0.5)  // t=0.5 → 100x100
        snapshotFrame(named: "end", delta: 0.5)     // t=1.0 → settled 150x150
    }

    /// The same transaction on a textured Sprite (opacity rides
    /// RenderGroup.opacity here, unlike color fills): frame-1 of the
    /// hud-sprite sheet grows 1x → 3x while fading in, linear, so the
    /// middle frame is exactly 2x at 0.625 opacity.
    func testSpriteScaleAndOpacityTimeline() throws {
        preloadResources([.init(name: "hud-sprite", type: .image)])
        setHUD {
            Sprite("hud-sprite", frame: "frame-1")
                .scaleEffect(from: 1.0, to: 3.0)
                .opacity(from: 0.25, to: 1.0)
                .animated(duration: 1, timing: .linear, on: .appear)
        }
        snapshotFrame(named: "start")                // 16x16 at 0.25 opacity
        snapshotFrame(named: "middle", delta: 0.25)  // t=0.25 → 24x24 at 0.4375
        snapshotFrame(named: "end", delta: 0.75)     // t=1.0 → 48x48 settled, full
    }

    /// Scale and opacity share one transaction: a fade-in growing from
    /// nothing, snapshotted mid-flight (easeOut(0.25) = 0.4375).
    func testScaleAndOpacityShareTransactionMidFlight() throws {
        setHUD {
            Rectangle()
                .frame(width: 120, height: 120)
                .foregroundColor(.green)
                .scaleEffect(from: 0.0, to: 1.0)
                .opacity(from: 0.0, to: 1.0)
                .animated(duration: 1, timing: .easeOut, on: .appear)
        }
        snapshotFrame(named: "start")
        snapshotFrame(named: "middle", delta: 0.25)  // t=0.25 → 52.5pt at 0.4375
        snapshotFrame(named: "end", delta: 0.75)     // t=1.0 → settled, full
    }
}
