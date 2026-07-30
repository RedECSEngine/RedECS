import Geometry
import GeometryAlgorithms
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
    /// Interaction payloads volunteered for hit testing (set by `Button`).
    public var hit: ButtonHit?
    /// Marks this node as a scroll region for drag capture (set by `ScrollView`).
    public var scroll: ScrollRegion?
    /// Render-only local transform (e.g. `scaleEffect`): applied to this
    /// node's whole subtree at emit, in local space, without affecting
    /// layout frames or hit geometry.
    public var transform: Matrix3?
    /// Render-only opacity multiplier for the whole subtree.
    public var opacityFactor: Double?
    /// Clips this node's whole subtree to a rect in the node's local space
    /// (e.g. a `ScrollView` window). Applied at emit like `transform`, and
    /// translated up into viewport space as the subtree is reparented; nested
    /// clips intersect. Layout frames and hit geometry are unaffected.
    public var clip: Rect?
    /// Structural identity of the view that produced this node (its
    /// resolve-time `identityPath`), stamped in `_resolve`. Hit testing
    /// reports it so input tracking keys the same identity as animation —
    /// and, unlike a path rebuilt from child indices, it carries `ForEach`'s
    /// `.id` tokens.
    public var identity: [IdentityToken] = []

    public init(
        frame: Rect,
        groups: [RenderGroup] = [],
        children: [HUDNode] = [],
        hit: ButtonHit? = nil
    ) {
        self.frame = frame
        self.groups = groups
        self.children = children
        self.hit = hit
    }
}

public extension HUDNode {
    /// Flattens the tree into render groups in paint order (a node's own
    /// content, then its children in order). Reparenting is applied level by
    /// level — child groups first, then this node's translation — which
    /// reproduces the exact floating-point operation order of the previous
    /// recursive render path, keeping snapshot output bit-identical when no
    /// render effects are present.
    func flattenedGroups() -> [RenderGroup] {
        var flattened = groups + children.flatMap { child in
            child.flattenedGroups().map { $0.reparented(by: child.frame.origin) }
        }
        if let transform = transform {
            flattened = flattened.map {
                $0.withTransformMatrix(.multiply(transform, $0.transformMatrix))
            }
        }
        if let clip = clip {
            flattened = flattened.map { $0.applyingClip(clip) }
        }
        if let opacityFactor = opacityFactor {
            flattened = flattened.map { $0.applyingOpacityFactor(opacityFactor) }
        }
        return flattened
    }
}
