import XCTest
import Geometry
import RedECS
@testable import RedHUD

final class HUDHitTestTests: XCTestCase {
    private func node(
        x: Double, y: Double, width: Double, height: Double,
        hit: ButtonHit? = nil,
        identity: [IdentityToken] = [],
        children: [HUDNode] = []
    ) -> HUDNode {
        var node = HUDNode(
            frame: Rect(x: x, y: y, width: width, height: height),
            children: children,
            hit: hit
        )
        node.identity = identity
        return node
    }

    func testPointInsideAndOutside() {
        let root = node(x: 0, y: 0, width: 100, height: 50, hit: ButtonHit(up: "tapped"))
        XCTAssertEqual(root.hitTest(Point(x: 50, y: 25))?.hit.up as? String, "tapped")
        XCTAssertNil(root.hitTest(Point(x: 150, y: 25)))
        XCTAssertNil(root.hitTest(Point(x: 50, y: -1)))
    }

    func testContainmentIsHalfOpen() {
        let root = node(x: 0, y: 0, width: 100, height: 50, hit: ButtonHit(up: "a"))
        XCTAssertNotNil(root.hitTest(Point(x: 0, y: 0)))
        XCTAssertNil(root.hitTest(Point(x: 100, y: 25)))
        XCTAssertNil(root.hitTest(Point(x: 50, y: 50)))
    }

    func testPointTranslatesThroughNestedFrames() {
        // button at (10,10)-(30,30) inside a child container at (100,100).
        let button = node(x: 10, y: 10, width: 20, height: 20, hit: ButtonHit(down: "b"))
        let container = node(x: 100, y: 100, width: 50, height: 50, children: [button])
        let root = node(x: 0, y: 0, width: 480, height: 320, children: [container])

        XCTAssertEqual(root.hitTest(Point(x: 115, y: 115))?.hit.down as? String, "b")
        XCTAssertNil(root.hitTest(Point(x: 105, y: 105)))   // inside container, off button
    }

    func testTopmostSiblingWinsInReversePaintOrder() {
        let under = node(x: 0, y: 0, width: 40, height: 40, hit: ButtonHit(up: "under"))
        let over = node(x: 20, y: 20, width: 40, height: 40, hit: ButtonHit(up: "over"))
        let root = node(x: 0, y: 0, width: 100, height: 100, children: [under, over])

        // overlap region: later child (painted on top) wins
        XCTAssertEqual(root.hitTest(Point(x: 30, y: 30))?.hit.up as? String, "over")
        // non-overlapping part of the first child still hits
        XCTAssertEqual(root.hitTest(Point(x: 5, y: 5))?.hit.up as? String, "under")
    }

    func testDeepestInteractiveNodeBeatsAncestor() {
        let inner = node(x: 5, y: 5, width: 10, height: 10, hit: ButtonHit(up: "inner"))
        let outer = node(x: 0, y: 0, width: 50, height: 50, hit: ButtonHit(up: "outer"), children: [inner])

        XCTAssertEqual(outer.hitTest(Point(x: 8, y: 8))?.hit.up as? String, "inner")
        XCTAssertEqual(outer.hitTest(Point(x: 30, y: 30))?.hit.up as? String, "outer")
    }

    func testChildOutsideParentBoundsIsUnreachable() {
        let stray = node(x: 60, y: 0, width: 20, height: 20, hit: ButtonHit(up: "stray"))
        let root = node(x: 0, y: 0, width: 50, height: 50, children: [stray])
        // the point lands where the stray child draws, but it's outside the
        // root's bounds so descent never begins
        XCTAssertNil(root.hitTest(Point(x: 70, y: 10)))
    }

    func testIdentityPathReflectsStructure() {
        // Hit testing reports the identity stamped on the node during
        // resolve (here set to mimic the wrapper's second child).
        let target = node(
            x: 0, y: 0, width: 10, height: 10,
            hit: ButtonHit(up: "t"), identity: [.index(1), .index(1)]
        )
        let wrapper = node(x: 10, y: 10, width: 20, height: 20, children: [
            node(x: 0, y: 0, width: 5, height: 5),
            target,
        ])
        let root = node(x: 0, y: 0, width: 100, height: 100, children: [
            node(x: 50, y: 50, width: 10, height: 10),
            wrapper,
        ])
        let result = root.hitTest(Point(x: 12, y: 12))
        XCTAssertEqual(result?.identity, [.index(1), .index(1)])
    }

    func testNonInteractiveTreeReturnsNil() {
        let root = node(x: 0, y: 0, width: 100, height: 100, children: [
            node(x: 10, y: 10, width: 20, height: 20),
        ])
        XCTAssertNil(root.hitTest(Point(x: 15, y: 15)))
    }
}
