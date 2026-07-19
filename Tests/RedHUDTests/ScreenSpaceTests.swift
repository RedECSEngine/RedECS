import XCTest
import Geometry
import RedECS
@testable import RedHUD

final class ScreenSpaceTests: XCTestCase {
    let context = HUDRenderContext()
    let viewport = Size(width: 480, height: 320)

    func testFillsProposal() {
        let stack = ScreenSpace {
            Pin(.center) { Rectangle().frame(width: 10, height: 10) }
        }
        XCTAssertEqual(
            stack.size(proposed: ProposedSize(viewport), context: context),
            viewport
        )
    }

    func testPinsChildrenToTheirCorners() {
        let stack = ScreenSpace {
            Pin(.topLeading) { Rectangle().frame(width: 20, height: 10) }
            Pin(.bottomTrailing) { Rectangle().frame(width: 20, height: 10) }
            Pin(.center) { Rectangle().frame(width: 20, height: 10) }
        }
        let groups = stack.render(context: context, size: viewport)
        XCTAssertEqual(groups.count, 3)
        let origins = groups.map { Point.zero.multiplyingMatrix($0.transformMatrix) }
        XCTAssertEqual(origins[0], Point(x: 0, y: 0))
        XCTAssertEqual(origins[1], Point(x: 460, y: 310))
        XCTAssertEqual(origins[2], Point(x: 230, y: 155))
    }

    func testMultipleViewsInAPinWrapInVStack() {
        let stack = ScreenSpace {
            Pin(.topTrailing) {
                Rectangle().frame(width: 20, height: 10)
                Rectangle().frame(width: 20, height: 10)
            }
        }
        let groups = stack.render(context: context, size: viewport)
        XCTAssertEqual(groups.count, 2)
        let origins = groups.map { Point.zero.multiplyingMatrix($0.transformMatrix) }
        // 20x20 VStack pinned top-trailing in 480x320.
        XCTAssertEqual(origins[0], Point(x: 460, y: 0))
        XCTAssertEqual(origins[1], Point(x: 460, y: 10))
    }

    func testConditionalPins() {
        let showCentre = false
        let stack = ScreenSpace {
            Pin(.top) { Rectangle() }
            if showCentre {
                Pin(.center) { Rectangle() }
            }
        }
        XCTAssertEqual(stack.pins.count, 1)
    }
}
