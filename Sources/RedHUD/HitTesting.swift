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

/// A resolved hit: the payloads plus the structural identity of the node
/// that owns them (its stamped `identityPath`) — the key for pressed and
/// hovered tracking across frames.
public struct HUDHitResult {
    public var hit: ButtonHit
    public var identity: [IdentityToken]
}

public extension HUDNode {
    /// Finds the topmost interactive node containing `point` (in this
    /// node's local space). Children are checked in reverse paint order so
    /// what draws last wins; containment gates descent, and a node's own
    /// payload only answers when no descendant claimed the point first.
    /// Containment is half-open ([min, max)), so adjacent buttons never
    /// double-claim a shared edge.
    func hitTest(_ point: Point) -> HUDHitResult? {
        guard Rect(origin: .zero, size: frame.size).contains(point) else {
            return nil
        }
        for index in children.indices.reversed() {
            let child = children[index]
            if let result = child.hitTest(point.diffOf(child.frame.origin)) {
                return result
            }
        }
        return hit.map { HUDHitResult(hit: $0, identity: identity) }
    }
}
