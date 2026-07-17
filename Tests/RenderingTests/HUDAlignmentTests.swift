import XCTest
import RedECS
import RedHUD
import Geometry

@MainActor
class HUDAlignmentTests: HUDSnapshotTestCase {
    /// The headline feature in one image: nine squares, one pinned to each
    /// corner, edge midpoint, and the center of the viewport.
    func testNineViewportPins() throws {
        let positions: [(RedHUD.Alignment, Color)] = [
            (.topLeading, .red), (.top, .green), (.topTrailing, .blue),
            (.leading, .yellow), (.center, .white), (.trailing, .cyan),
            (.bottomLeading, .pink), (.bottom, .orange), (.bottomTrailing, .grey),
        ]
        setHUD {
            ViewportStack {
                for (alignment, color) in positions {
                    Pin(alignment) {
                        RedHUD.Rectangle()
                            .frame(width: 48, height: 48)
                            .foregroundColor(color)
                    }
                }
            }
        }
        snapshotFrame()
    }
}
