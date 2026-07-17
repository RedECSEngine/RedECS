import XCTest
import Geometry
import RedECS
@testable import RedHUD

final class FixedFrameTests: XCTestCase {
    let context = HUDRenderContext()

    func testFullyFixedFrameReportsItsOwnSize() {
        let view = Rectangle().frame(width: 80, height: 30)
        let size = view.size(proposed: ProposedSize(width: 500, height: 500), context: context)
        XCTAssertEqual(size, Size(width: 80, height: 30))
    }

    func testPartiallyFixedFrameAdoptsChildOtherAxis() {
        // Rectangle adopts any proposal, so the open axis takes the parent's
        // proposal passed through the frame.
        let view = Rectangle().frame(height: 30)
        let size = view.size(proposed: ProposedSize(width: 500, height: 500), context: context)
        XCTAssertEqual(size, Size(width: 500, height: 30))
    }

    func testUnproposedOpenAxisFallsBackToChildDefault() {
        let view = Rectangle().frame(width: 80)
        let size = view.size(proposed: ProposedSize(), context: context)
        XCTAssertEqual(size, Size(width: 80, height: 10))
    }

    func testAlignmentOffsetsChildGroups() {
        // A 10x10 rectangle inside a 100x50 frame, bottom-trailing:
        // child renders at local origin and is reparented by (90, 40).
        let view = Rectangle()
            .frame(width: 10, height: 10)
            .frame(width: 100, height: 50, alignment: .bottomTrailing)
        let groups = view.render(context: context, size: Size(width: 100, height: 50))
        XCTAssertEqual(groups.count, 1)
        let corner = Point(x: 0, y: 0).multiplyingMatrix(groups[0].transformMatrix)
        XCTAssertEqual(corner, Point(x: 90, y: 40))
    }

    func testCenterAlignmentIsDefault() {
        let view = Rectangle()
            .frame(width: 10, height: 10)
            .frame(width: 100, height: 50)
        let groups = view.render(context: context, size: Size(width: 100, height: 50))
        let corner = Point(x: 0, y: 0).multiplyingMatrix(groups[0].transformMatrix)
        XCTAssertEqual(corner, Point(x: 45, y: 20))
    }
}
