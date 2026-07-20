import Geometry
import RedECS

/// The interaction payloads a node volunteers for hit testing (a `Button`'s
/// actions, type-erased; the reducer casts back to the game's action type).
public struct ButtonHit {
    public var down: Any?
    public var up: Any?
    public var hover: Any?

    public init(down: Any? = nil, up: Any? = nil, hover: Any? = nil) {
        self.down = down
        self.up = up
        self.hover = hover
    }
}

/// The scroll axis a `ScrollView` scrolls along.
public enum ScrollAxis: Hashable, Sendable {
    case vertical
    case horizontal
}

/// A node's registration as a scroll region, so drags over it (or over its
/// content) are captured to it. Set by `ScrollView`, the parallel of `hit`.
public struct ScrollRegion {
    public var axis: ScrollAxis
    public init(axis: ScrollAxis) { self.axis = axis }
}

/// The scroll region enclosing a hit, with its identity (the drag key).
public struct ScrollHit {
    public var identity: [IdentityToken]
    public var region: ScrollRegion
}

/// A resolved hit: the topmost interactive node's payloads (nil if the point
/// landed on non-button content), its identity, and the innermost scroll
/// region enclosing the point (nil if none) — the key for pressed/hovered
/// tracking and drag capture across frames.
public struct HUDHitResult {
    public var hit: ButtonHit?
    public var identity: [IdentityToken]
    public var scroll: ScrollHit?
}

public extension HUDNode {
    /// Finds the topmost interactive node containing `point` (in this node's
    /// local space), carrying along the innermost enclosing scroll region.
    /// Children are checked in reverse paint order so what draws last wins;
    /// containment gates descent (half-open, so adjacent buttons never
    /// double-claim an edge). A node answers with its own `hit` when no
    /// descendant claimed the point; a point inside a scroll region with no
    /// button still resolves (hit nil) so a drag can be captured over gaps.
    func hitTest(_ point: Point) -> HUDHitResult? {
        hitTest(point, enclosingScroll: nil)
    }

    private func hitTest(_ point: Point, enclosingScroll: ScrollHit?) -> HUDHitResult? {
        guard Rect(origin: .zero, size: frame.size).contains(point) else {
            return nil
        }
        // This node's own scroll region (if any) becomes the enclosing region
        // for everything below it.
        let scrollHere = scroll.map { ScrollHit(identity: identity, region: $0) } ?? enclosingScroll
        for index in children.indices.reversed() {
            let child = children[index]
            if let result = child.hitTest(
                point.diffOf(child.frame.origin),
                enclosingScroll: scrollHere
            ) {
                return result
            }
        }
        if let hit = hit {
            return HUDHitResult(hit: hit, identity: identity, scroll: scrollHere)
        }
        // Only a scroll-region node itself claims an otherwise-empty point (so a
        // drag can start over blank content). Plain leaves return nil, so they
        // never short-circuit an ancestor Button inside the scroll region.
        if scroll != nil {
            return HUDHitResult(hit: nil, identity: identity, scroll: scrollHere)
        }
        return nil
    }
}
