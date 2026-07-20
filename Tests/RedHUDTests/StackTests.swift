import XCTest
import Geometry
import RedECS
@testable import RedHUD

final class StackTests: XCTestCase {
    let context = HUDRenderContext()

    func testHStackSizeSumsFixedChildren() {
        let stack = HStack {
            Rectangle().frame(width: 30, height: 20)
            Rectangle().frame(width: 50, height: 40)
        }
        let size = stack.size(proposed: ProposedSize(width: 200, height: 100), context: context)
        XCTAssertEqual(size, Size(width: 80, height: 40))
    }

    func testHStackSpacingCountsBetweenChildren() {
        let stack = HStack(spacing: 8) {
            Rectangle().frame(width: 30, height: 20)
            Rectangle().frame(width: 50, height: 40)
            Rectangle().frame(width: 10, height: 10)
        }
        let size = stack.size(proposed: ProposedSize(width: 300, height: 100), context: context)
        XCTAssertEqual(size, Size(width: 90 + 16, height: 40))
    }

    func testHStackDividesRemainingWidthAmongFlexibleChildren() {
        // Bare rectangles adopt whatever is proposed: 200 across two → 100 each.
        let stack = HStack {
            Rectangle()
            Rectangle()
        }
        let size = stack.size(proposed: ProposedSize(width: 200, height: 50), context: context)
        XCTAssertEqual(size, Size(width: 200, height: 50))
    }

    func testHStackRedistributesUnusedWidth() {
        // First child is offered 100 but takes 40; the second is then offered 160.
        let stack = HStack {
            Rectangle().frame(width: 40, height: 10)
            Rectangle()
        }
        let size = stack.size(proposed: ProposedSize(width: 200, height: 50), context: context)
        XCTAssertEqual(size, Size(width: 200, height: 50))
    }

    func testHStackRenderPositionsAndAlignment() {
        let stack = HStack(alignment: .bottom) {
            Rectangle().frame(width: 30, height: 20)
            Rectangle().frame(width: 50, height: 40)
        }
        let stackSize = Size(width: 80, height: 40)
        let groups = stack.render(context: context, size: stackSize)
        XCTAssertEqual(groups.count, 2)
        let firstOrigin = Point.zero.multiplyingMatrix(groups[0].transformMatrix)
        let secondOrigin = Point.zero.multiplyingMatrix(groups[1].transformMatrix)
        XCTAssertEqual(firstOrigin, Point(x: 0, y: 20))   // bottom-aligned 20-tall in 40
        XCTAssertEqual(secondOrigin, Point(x: 30, y: 0))
    }

    func testVStackMirrorsHStack() {
        let stack = VStack(alignment: .trailing, spacing: 5) {
            Rectangle().frame(width: 20, height: 30)
            Rectangle().frame(width: 40, height: 50)
        }
        let size = stack.size(proposed: ProposedSize(width: 100, height: 300), context: context)
        XCTAssertEqual(size, Size(width: 40, height: 85))

        let groups = stack.render(context: context, size: size)
        let firstOrigin = Point.zero.multiplyingMatrix(groups[0].transformMatrix)
        let secondOrigin = Point.zero.multiplyingMatrix(groups[1].transformMatrix)
        XCTAssertEqual(firstOrigin, Point(x: 20, y: 0))   // trailing-aligned 20-wide in 40
        XCTAssertEqual(secondOrigin, Point(x: 0, y: 35))
    }

    func testNestedStacksCompose() {
        let view = VStack {
            HStack {
                Rectangle().frame(width: 10, height: 10)
                Rectangle().frame(width: 10, height: 10)
            }
            Rectangle().frame(width: 30, height: 5)
        }
        let size = view.size(proposed: ProposedSize(width: 100, height: 100), context: context)
        XCTAssertEqual(size, Size(width: 30, height: 15))
    }

    func testUnproposedAxisUsesIdealSizes() {
        let stack = HStack {
            Rectangle().frame(width: 25, height: 10)
            Rectangle() // ideal 100x100 (ProposedSize.orDefault)
        }
        let size = stack.size(proposed: ProposedSize(), context: context)
        XCTAssertEqual(size, Size(width: 125, height: 100))
    }
}
