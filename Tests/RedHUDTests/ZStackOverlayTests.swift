import XCTest
import Geometry
import RedECS
@testable import RedHUD

final class ZStackOverlayTests: XCTestCase {
    let context = HUDRenderContext()

    // MARK: ZStack

    /// ZStack sizes to the union of its children.
    func testZStackSizesToUnionOfChildren() {
        let stack = ZStack {
            Rectangle().frame(width: 30, height: 80)
            Rectangle().frame(width: 90, height: 20)
        }
        let size = stack.size(proposed: ProposedSize(width: 200, height: 200), context: context)
        XCTAssertEqual(size, Size(width: 90, height: 80))
    }

    /// Each child is offered the ZStack's own proposal (not a divided share),
    /// so a bare, flexible child fills the whole proposal.
    func testZStackProposesFullProposalToEachChild() {
        let stack = ZStack {
            Rectangle()
            Rectangle().frame(width: 40, height: 40)
        }
        let size = stack.size(proposed: ProposedSize(width: 120, height: 90), context: context)
        XCTAssertEqual(size, Size(width: 120, height: 90))
    }

    /// Children are aligned within the union; a centered small child sits at
    /// the middle of the larger one.
    func testZStackCentersChildrenByDefault() {
        let node = ZStack {
            Rectangle().frame(width: 100, height: 100)
            Rectangle().frame(width: 20, height: 20)
        }._resolve(proposed: ProposedSize(width: 100, height: 100), context: context)
        XCTAssertEqual(node.children[1].frame.origin, Point(x: 40, y: 40))
    }

    /// Alignment places children against the requested corner.
    func testZStackTopLeadingAlignment() {
        let node = ZStack(alignment: .topLeading) {
            Rectangle().frame(width: 100, height: 100)
            Rectangle().frame(width: 20, height: 20)
        }._resolve(proposed: ProposedSize(width: 100, height: 100), context: context)
        XCTAssertEqual(node.children[1].frame.origin, Point(x: 0, y: 0))
    }

    /// Paint order is source order: the last child hit-tests on top.
    func testZStackLastChildPaintsAndHitsOnTop() {
        let node = ZStack {
            Rectangle().frame(width: 50, height: 50)
            Button(up: "top") { Rectangle().frame(width: 50, height: 50) }
        }._resolve(proposed: ProposedSize(width: 50, height: 50), context: context)
        XCTAssertEqual(node.hitTest(Point(x: 25, y: 25))?.hit.up as? String, "top")
    }

    /// A ForEach inside a ZStack keys its layers by element id, just like in
    /// the linear stacks.
    func testZStackForEachKeysLayersById() {
        func identities(_ items: [String]) -> [[IdentityToken]] {
            ZStack {
                ForEach(items, id: \.self) { _ in
                    Rectangle().frame(width: 10, height: 10)
                }
            }._resolve(proposed: ProposedSize(width: 50, height: 50), context: context)
                .children.map(\.identity)
        }
        let original = identities(["a", "b"])
        let swapped = identities(["b", "a"])
        XCTAssertEqual(original[0], swapped[1])
        XCTAssertNotEqual(original[0], swapped[0])
    }

    // MARK: Overlay

    /// The overlay never changes the base's reported size.
    func testOverlayReportsBaseSize() {
        let view = Rectangle().frame(width: 60, height: 40).overlay {
            Rectangle().frame(width: 200, height: 200)
        }
        let size = view.size(proposed: ProposedSize(width: 500, height: 500), context: context)
        XCTAssertEqual(size, Size(width: 60, height: 40))
    }

    /// The overlay is offered the base's size, so a flexible overlay fills the
    /// base exactly.
    func testOverlayProposesBaseSizeToOverlay() {
        let node = Rectangle().frame(width: 60, height: 40).overlay {
            Rectangle()  // flexible: adopts whatever it is proposed
        }._resolve(proposed: ProposedSize(width: 500, height: 500), context: context)
        XCTAssertEqual(node.children[1].frame.size, Size(width: 60, height: 40))
        XCTAssertEqual(node.children[1].frame.origin, .zero)
    }

    /// The overlay aligns within the base bounds.
    func testOverlayAlignsWithinBase() {
        let node = Rectangle().frame(width: 100, height: 100).overlay(alignment: .bottomTrailing) {
            Rectangle().frame(width: 20, height: 20)
        }._resolve(proposed: ProposedSize(width: 100, height: 100), context: context)
        XCTAssertEqual(node.children[1].frame.origin, Point(x: 80, y: 80))
    }

    /// The overlay paints over the base and hit-tests on top of it.
    func testOverlayHitsOnTopOfBase() {
        let node = Button(up: "base") { Rectangle().frame(width: 100, height: 100) }
            .overlay {
                Button(up: "over") { Rectangle().frame(width: 40, height: 40) }
            }
            ._resolve(proposed: ProposedSize(width: 100, height: 100), context: context)
        // center is under the overlay; a corner is base-only
        XCTAssertEqual(node.hitTest(Point(x: 50, y: 50))?.hit.up as? String, "over")
        XCTAssertEqual(node.hitTest(Point(x: 5, y: 5))?.hit.up as? String, "base")
    }
}
