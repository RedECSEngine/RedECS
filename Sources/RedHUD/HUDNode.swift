import Geometry
import RedECS

/// The resolved form of a view: its frame, what it draws itself, and its
/// resolved children. Layout produces one of these per view per frame; the
/// tree is what gets emitted to the renderer, and (in later milestones) what
/// hit testing and animation walk.
public struct HUDNode {
    /// This node's frame in its PARENT's coordinate space, so a subtree is
    /// valid wherever its parent places it.
    public var frame: Rect
    /// What this view draws itself, in its own local space (leaf output;
    /// containers usually leave this empty).
    public var groups: [RenderGroup]
    public var children: [HUDNode]

    public init(
        frame: Rect,
        groups: [RenderGroup] = [],
        children: [HUDNode] = []
    ) {
        self.frame = frame
        self.groups = groups
        self.children = children
    }
}

public extension HUDNode {
    /// Flattens the tree into render groups in paint order (a node's own
    /// content, then its children in order). Reparenting is applied level by
    /// level — child groups first, then this node's translation — which
    /// reproduces the exact floating-point operation order of the previous
    /// recursive render path, keeping snapshot output bit-identical.
    func flattenedGroups() -> [RenderGroup] {
        groups + children.flatMap { child in
            child.flattenedGroups().map { $0.reparented(by: child.frame.origin) }
        }
    }
}
