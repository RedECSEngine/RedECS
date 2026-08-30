import XCTest
import Geometry
import RedECS
@testable import RedHUD

final class PaddingTests: XCTestCase {
    func testGrowsAroundContentAndInsetsIt() {
        let node = Rectangle().frame(width: 20, height: 10).padding(6)
            ._resolve(proposed: ProposedSize(), context: HUDRenderContext())
        XCTAssertEqual(node.frame.size, Size(width: 32, height: 22))
        XCTAssertEqual(node.children[0].frame.origin, Point(x: 6, y: 6))
    }

    func testShrinksTheProposal() {
        // An unsized Rectangle adopts the proposal, minus the insets.
        let node = Rectangle().padding(10)
            ._resolve(proposed: ProposedSize(Size(width: 100, height: 50)), context: HUDRenderContext())
        XCTAssertEqual(node.children[0].frame.size, Size(width: 80, height: 30))
        XCTAssertEqual(node.frame.size, Size(width: 100, height: 50))
    }

    func testOversizedInsetsClampTheProposalAtZero() {
        let node = Rectangle().padding(40)
            ._resolve(proposed: ProposedSize(Size(width: 50, height: 50)), context: HUDRenderContext())
        XCTAssertEqual(node.children[0].frame.size, Size(width: 0, height: 0))
    }
}
