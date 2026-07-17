import XCTest
import RedECS
import RedHUD
import Geometry

@MainActor
class HUDOverWorldTests: HUDSnapshotTestCase {
    /// A world sprite seen through an offset camera with a pinned HUD in the
    /// same frame: HUD corners must hug the viewport (ignoring the camera)
    /// and paint above the world sprite.
    func testHUDIgnoresCameraAndPaintsAboveWorld() throws {
        let worldId = "world-box"
        store.sendSystemAction(.addEntity(worldId, []))
        store.sendSystemAction(.addComponent(
            TransformComponent(entity: worldId, position: Point(x: 100, y: 100)),
            into: \.transform
        ))
        store.sendSystemAction(.addComponent(
            SpriteComponent(
                entity: worldId,
                shape: .rect(Rect(origin: .zero, size: Size(width: 200, height: 200))),
                fillColor: .green
            ),
            into: \.sprite
        ))

        let cameraId = "camera"
        store.sendSystemAction(.addEntity(cameraId, []))
        store.sendSystemAction(.addComponent(
            TransformComponent(entity: cameraId, position: Point(x: 40, y: 60)),
            into: \.transform
        ))
        store.sendSystemAction(.addComponent(
            CameraComponent(entity: cameraId, zoom: 2),
            into: \.camera
        ))

        setHUD {
            ViewportStack {
                Pin(.topLeading) {
                    Rectangle().frame(width: 60, height: 60).foregroundColor(.red)
                }
                Pin(.bottomTrailing) {
                    Rectangle().frame(width: 60, height: 60).foregroundColor(.blue)
                }
                Pin(.center) {
                    Rectangle().frame(width: 40, height: 40).foregroundColor(.white)
                }
            }
        }
        snapshotFrame()
    }
}
