import XCTest
import Geometry
import RedECS
@testable import RedHUD

final class HUDComponentTests: XCTestCase {
    func testContentIsTransientAcrossCoding() throws {
        let component = HUDComponent(entity: "hud", zIndex: 3, revision: 7) {
            Rectangle().frame(width: 10, height: 10)
        }
        XCTAssertNotNil(component.content)

        let encoded = try JSONEncoder().encode(component)
        let decoded = try JSONDecoder().decode(HUDComponent.self, from: encoded)
        XCTAssertNil(decoded.content)
        XCTAssertEqual(decoded.entity, "hud")
        XCTAssertEqual(decoded.zIndex, 3)
        XCTAssertEqual(decoded.revision, 7)
        // Equality ignores content by design; revision is the change signal.
        XCTAssertEqual(decoded, component)
    }

    func testSetContentBumpsRevision() {
        var component = HUDComponent(entity: "hud") {
            Rectangle()
        }
        let before = component
        component.setContent {
            Rectangle()
            Rectangle()
        }
        XCTAssertEqual(component.revision, 1)
        XCTAssertNotEqual(component, before)
    }

    func testEmptyBuilderMeansNoContent() {
        let component = HUDComponent(entity: "hud") {}
        XCTAssertNil(component.content)
    }
}
