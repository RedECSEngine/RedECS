import XCTest
import RedECS
import RedHUD
import Geometry

@MainActor
class HUDTextTests: HUDSnapshotTestCase {
    func testTextCentered() throws {
        preloadFont()
        setHUD {
            RedHUD.Text("Hello HUD", font: "PT-Mono")
        }
        snapshotFrame()
    }

    func testTextPinnedWithShapesInHStack() throws {
        preloadFont()
        setHUD {
            ViewportStack {
                Pin(.topLeading) {
                    HStack(alignment: .center, spacing: 12) {
                        RedHUD.Rectangle()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.red)
                        RedHUD.Text("Score: 120")
                    }
                }
                Pin(.bottom) {
                    RedHUD.Text("descenders gyp")
                }
            }
            .font("PT-Mono")
        }
        snapshotFrame()
    }
}
