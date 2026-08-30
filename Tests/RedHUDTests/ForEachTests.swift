import XCTest
import Geometry
import RedECS
@testable import RedHUD

final class ForEachTests: XCTestCase {
    let context = HUDRenderContext()

    /// ForEach owns no layout: it splices its element views into the parent,
    /// which stacks them. Three 10×20 rows in a VStack size to 10×60 — not
    /// overlapped at the origin.
    func testForEachIsLaidOutByItsParent() {
        let stack = VStack {
            ForEach(["a", "b", "c"], id: \.self) { _ in
                Rectangle().frame(width: 10, height: 20)
            }
        }
        let size = stack.size(proposed: ProposedSize(width: 100, height: 100), context: context)
        XCTAssertEqual(size, Size(width: 10, height: 60))
    }

    /// ForEach expansion interleaves with statically-placed siblings.
    func testForEachComposesWithStaticSiblings() {
        let stack = VStack {
            Rectangle().frame(width: 10, height: 5)
            ForEach(["a", "b"], id: \.self) { _ in
                Rectangle().frame(width: 10, height: 20)
            }
            Rectangle().frame(width: 10, height: 5)
        }
        let node = stack._resolve(
            proposed: ProposedSize(width: 100, height: 100),
            context: context
        )
        XCTAssertEqual(node.children.count, 4)
        XCTAssertEqual(node.frame.size, Size(width: 10, height: 50))
    }

    /// The crux: a child's identity is keyed by *which element* it is, so it
    /// follows the element across a reorder rather than staying with the
    /// slot — this is what keeps animation and input state attached to the
    /// right row when the collection is edited.
    func testIdentityFollowsElementAcrossReorder() {
        func identities(_ items: [String]) -> [[IdentityToken]] {
            let stack = VStack {
                ForEach(items, id: \.self) { _ in
                    Rectangle().frame(width: 10, height: 20)
                }
            }
            return stack._resolve(
                proposed: ProposedSize(width: 100, height: 100),
                context: context
            ).children.map(\.identity)
        }

        let original = identities(["a", "b", "c"])
        let reordered = identities(["b", "a", "c"])

        // "a" moved from slot 0 to slot 1 but carries the same identity.
        XCTAssertEqual(original[0], reordered[1])
        // "b" moved from slot 1 to slot 0, same identity.
        XCTAssertEqual(original[1], reordered[0])
        // "c" never moved — same slot, same identity.
        XCTAssertEqual(original[2], reordered[2])
        // Identity is id-based, not positional: slot 0 holds different
        // elements in the two orders, so its identity differs.
        XCTAssertNotEqual(original[0], reordered[0])
    }

    /// Distinct elements get distinct identities; an element that expands to
    /// several views keeps them distinct too (id + sub-index).
    func testIdentitiesAreUniquePerElementView() {
        let stack = VStack {
            ForEach(["a", "b"], id: \.self) { _ in
                Rectangle().frame(width: 10, height: 10)
                Rectangle().frame(width: 10, height: 10)
            }
        }
        let identities = stack._resolve(
            proposed: ProposedSize(width: 100, height: 100),
            context: context
        ).children.map(\.identity)
        XCTAssertEqual(identities.count, 4)
        XCTAssertEqual(Set(identities.map { $0.description }).count, 4)
    }
}

private extension Array where Element == IdentityToken {
    var description: String { map { "\($0)" }.joined(separator: "/") }
}
