import Geometry
import GeometryAlgorithms
import RedECS

/// One absolutely-placed entry in a `WorldSpace`: content anchored at world
/// point `position`. The world mirror of `Pin`, but positional (x/y) rather
/// than aligned — world space has no viewport to align against. `alignment`
/// picks which horizontal edge of the content the point pins: `.leading`
/// (default) sits the content's left at the point; `.center` centers it over
/// the point; `.trailing` sits its right there. Vertical placement is always
/// top-at-`position` (centering the y would fight the y-down → y-up flip, so
/// it's left out). Multiple views are implicitly wrapped in a `VStack`.
public struct WorldPosition {
    public var position: Point
    public var alignment: HorizontalAlignment
    public var content: AnyHUDView

    public init(
        x: Double,
        y: Double,
        alignment: HorizontalAlignment = .leading,
        @HUDViewBuilder content: () -> [AnyHUDView]
    ) {
        self.position = Point(x: x, y: y)
        self.alignment = alignment
        let views = content()
        if views.count == 1 {
            self.content = views[0]
        } else {
            self.content = AnyHUDView(VStack { views })
        }
    }
}

@resultBuilder
public enum WorldSpaceBuilder {
    public static func buildExpression(_ entry: WorldPosition) -> [WorldPosition] { [entry] }
    public static func buildBlock(_ components: [WorldPosition]...) -> [WorldPosition] { components.flatMap { $0 } }
    public static func buildOptional(_ component: [WorldPosition]?) -> [WorldPosition] { component ?? [] }
    public static func buildEither(first component: [WorldPosition]) -> [WorldPosition] { component }
    public static func buildEither(second component: [WorldPosition]) -> [WorldPosition] { component }
    public static func buildArray(_ components: [[WorldPosition]]) -> [WorldPosition] { components.flatMap { $0 } }
}

/// A world-space layer: each entry is resolved at its intrinsic size and
/// placed at its own world coordinate, rather than filled to a viewport and
/// pinned like `ScreenSpace`. Its leaves stamp `.world`, so the primary
/// camera's projection places them in the scene — they pan and zoom with the
/// world. Later entries paint over earlier ones. Content is authored y-down in
/// world units (1 unit = 1 pixel at zoom 1). It is *positional*, not a flow
/// stack — hence `Space`, not `Stack`.
///
/// World space is y-up (a `WorldPosition(x:y:)` coincides with a sprite's
/// `TransformComponent` position), so each entry's y-down content is flipped
/// through `scale(1, -1)` about its own origin during placement: the content's
/// top-left anchors at the world point and reads downward on screen, with
/// glyphs upright. The flip is the outermost render transform, so it composes
/// over — and does not disturb — the content's own `scaleEffect`/animation.
///
/// It is the sole boundary that enters world space: `enteringWorldSpace()`
/// sets `context.projectionSpace = .world` (so the subtree's leaves stamp
/// their own groups) and hands back the flip — the two are bound together so
/// one can't be applied without the other.
public struct WorldSpace: BuiltinHUDView {
    public var entries: [WorldPosition]

    public init(@WorldSpaceBuilder content: () -> [WorldPosition]) {
        self.entries = content()
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        let (worldContext, flip) = context.enteringWorldSpace()
        let placed = entries.enumerated().map { index, entry -> HUDNode in
            var child = entry.content.resolve(
                proposed: ProposedSize(width: nil, height: nil),
                context: worldContext.descending(into: index)
            )
            child.frame.origin = Point(
                x: entry.position.x - entry.alignment.value(in: child.frame.size.width),
                y: entry.position.y
            )
            child.transform = child.transform.map { .multiply(flip, $0) } ?? flip
            return child
        }
        // No extent of its own — entries are absolutely placed, so nothing
        // stacks around them.
        return HUDNode(frame: Rect(origin: .zero, size: .zero), children: placed)
    }
}
