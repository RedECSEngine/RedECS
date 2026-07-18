import XCTest
import RedECS
import RedHUD
import Geometry

@MainActor
class HUDButtonTests: HUDSnapshotTestCase {
    /// A 120x60 button centered in the viewport, styled by its interaction
    /// state, driven through the store's real action pipeline: idle, then
    /// pressed via pointerDown at its center, then released.
    func testPressedStateStylesButton() throws {
        preloadFont()
        setHUD {
            Button(up: RenderingTestAction.buttonFired("tapped")) { interaction in
                ViewportStack {
                    Pin(.center) {
                        Rectangle()
                            .frame(width: 120, height: 60)
                            .foregroundColor(interaction.isPressed ? .yellow : .grey)
                    }
                    Pin(.center) {
                        Text("Play").font("PT-Mono").scaleEffect(0.5)
                    }
                }
                .frame(width: 120, height: 60)
            }
        }
        snapshotFrame(named: "idle")

        store.sendAction(.hud(.pointerDown(Point(x: 240, y: 240))))
        snapshotFrame(named: "pressed")
        XCTAssertEqual(store.state.firedActions, [], "up-only button must not fire on press")

        store.sendAction(.hud(.pointerUp(Point(x: 240, y: 240))))
        snapshotFrame(named: "released")
        // the .triggered round trip: HUD reducer → pullback wrap →
        // TestGameLogicReducer observes it, exactly once
        XCTAssertEqual(store.state.firedActions, ["tapped"])
    }
}
