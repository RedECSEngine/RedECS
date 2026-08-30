import XCTest
import RedECS
import RedHUD
import Geometry

@MainActor
class HUDStackTests: HUDSnapshotTestCase {
    func testHStackAlignmentsAndSpacing() throws {
        setHUD {
            VStack(spacing: 20) {
                HStack(alignment: .top, spacing: 10) {
                    Rectangle().frame(width: 40, height: 20).foregroundColor(.red)
                    Rectangle().frame(width: 40, height: 60).foregroundColor(.green)
                    Rectangle().frame(width: 40, height: 40).foregroundColor(.blue)
                }
                HStack(alignment: .center, spacing: 10) {
                    Rectangle().frame(width: 40, height: 20).foregroundColor(.red)
                    Rectangle().frame(width: 40, height: 60).foregroundColor(.green)
                    Rectangle().frame(width: 40, height: 40).foregroundColor(.blue)
                }
                HStack(alignment: .bottom, spacing: 10) {
                    Rectangle().frame(width: 40, height: 20).foregroundColor(.red)
                    Rectangle().frame(width: 40, height: 60).foregroundColor(.green)
                    Rectangle().frame(width: 40, height: 40).foregroundColor(.blue)
                }
            }
        }
        snapshotFrame()
    }

    func testVStackNestedInPinnedCorner() throws {
        setHUD {
            ScreenSpace {
                Pin(.topTrailing) {
                    VStack(alignment: .trailing, spacing: 8) {
                        Rectangle().frame(width: 120, height: 24).foregroundColor(.red)
                        Rectangle().frame(width: 80, height: 24).foregroundColor(.yellow)
                        Rectangle().frame(width: 40, height: 24).foregroundColor(.green)
                    }
                }
            }
        }
        snapshotFrame()
    }
}
