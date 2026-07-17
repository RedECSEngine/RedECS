import XCTest
import Geometry
@testable import RedHUD

final class AlignmentTests: XCTestCase {
    let size = Size(width: 100, height: 50)

    func testAlignmentPoints() {
        XCTAssertEqual(Alignment.topLeading.point(for: size), Point(x: 0, y: 0))
        XCTAssertEqual(Alignment.top.point(for: size), Point(x: 50, y: 0))
        XCTAssertEqual(Alignment.topTrailing.point(for: size), Point(x: 100, y: 0))
        XCTAssertEqual(Alignment.leading.point(for: size), Point(x: 0, y: 25))
        XCTAssertEqual(Alignment.center.point(for: size), Point(x: 50, y: 25))
        XCTAssertEqual(Alignment.trailing.point(for: size), Point(x: 100, y: 25))
        XCTAssertEqual(Alignment.bottomLeading.point(for: size), Point(x: 0, y: 50))
        XCTAssertEqual(Alignment.bottom.point(for: size), Point(x: 50, y: 50))
        XCTAssertEqual(Alignment.bottomTrailing.point(for: size), Point(x: 100, y: 50))
    }

    func testChildOffset() {
        let child = Size(width: 20, height: 10)
        XCTAssertEqual(
            Alignment.topLeading.offset(forChild: child, in: size),
            Point(x: 0, y: 0)
        )
        XCTAssertEqual(
            Alignment.center.offset(forChild: child, in: size),
            Point(x: 40, y: 20)
        )
        XCTAssertEqual(
            Alignment.bottomTrailing.offset(forChild: child, in: size),
            Point(x: 80, y: 40)
        )
    }
}
