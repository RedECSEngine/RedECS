import XCTest
import RedECS
import RedHUD
import Geometry

@MainActor
class HUDZStackOverlayTests: HUDSnapshotTestCase {
    /// Three concentric rectangles layered largest-to-smallest, centered by
    /// default; the stack sizes to the largest.
    func testZStackLayersCentered() throws {
        setHUD {
            ZStack {
                Rectangle().frame(width: 200, height: 200).foregroundColor(.red)
                Rectangle().frame(width: 120, height: 120).foregroundColor(.green)
                Rectangle().frame(width: 50, height: 50).foregroundColor(.blue)
            }
        }
        snapshotFrame()
    }

    /// Alignment drives the corner each layer settles into.
    func testZStackTopLeadingAlignment() throws {
        setHUD {
            ZStack(alignment: .topLeading) {
                Rectangle().frame(width: 200, height: 200).foregroundColor(.red)
                Rectangle().frame(width: 120, height: 120).foregroundColor(.green)
                Rectangle().frame(width: 50, height: 50).foregroundColor(.blue)
            }
        }
        snapshotFrame()
    }

    /// A badge overlaid on the top-trailing corner of a base panel; the
    /// overlay does not change the panel's size.
    func testOverlayBadgeInCorner() throws {
        setHUD {
            Rectangle()
                .frame(width: 200, height: 120)
                .foregroundColor(.blue)
                .overlay(alignment: .topTrailing) {
                    Rectangle().frame(width: 32, height: 32).foregroundColor(.red)
                }
        }
        snapshotFrame()
    }
}
