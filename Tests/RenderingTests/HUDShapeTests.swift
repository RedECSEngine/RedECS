import XCTest
import RedECS
import RedHUD
import Geometry

@MainActor
class HUDShapeTests: HUDSnapshotTestCase {
    func testCenteredRectangle() throws {
        setHUD {
            Rectangle()
                .frame(width: 200, height: 120)
                .foregroundColor(.red)
        }
        snapshotFrame()
    }

    func testNestedFramesAlignInsideEachOther() throws {
        // Frames draw nothing themselves; the blue box lands bottom-trailing
        // of the inner frame, which is centered in the outer one.
        setHUD {
            Rectangle()
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
                .frame(width: 300, height: 200, alignment: .bottomTrailing)
                .frame(width: 320, height: 220)
        }
        snapshotFrame()
    }
}
