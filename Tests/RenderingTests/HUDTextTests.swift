import XCTest
import RedECS
import RedHUD
import Geometry

@MainActor
class HUDTextTests: HUDSnapshotTestCase {
    func testTextCentered() throws {
        preloadFont()
        setHUD {
            Text("Hello HUD").font("PT-Mono")
        }
        snapshotFrame()
    }

    /// No preload, no .font(): the embedded default font registered by
    /// MetalResourceManager at init renders with zero game-side setup.
    func testTextRendersWithEmbeddedDefaultFont() throws {
        setHUD {
            Text("Default Font")
        }
        snapshotFrame()
    }

    func testTextPinnedWithShapesInHStack() throws {
        preloadFont()
        setHUD {
            ViewportStack {
                Pin(.topLeading) {
                    HStack(alignment: .center, spacing: 12) {
                        Rectangle()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.red)
                        Text("Score: 120")
                    }
                }
                Pin(.bottom) {
                    Text("descenders gyp")
                }
            }
            .font("PT-Mono")
        }
        snapshotFrame()
    }
}
