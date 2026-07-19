import Geometry
import RedECS

/// Layers children on a shared origin: every child is offered the same
/// proposal the ZStack received, the stack sizes to the union (max width,
/// max height) of what they choose, and each child is placed within that
/// union by `alignment` (default centered). Later children paint over
/// earlier ones, mirroring `HStack`/`VStack`'s per-child identity so a
/// `ForEach` inside a ZStack keys its layers by element id.
public struct ZStack: BuiltinHUDView {
    public var children: [AnyHUDView]
    public var alignment: Alignment

    public init(
        alignment: Alignment = .center,
        @HUDViewBuilder content: () -> [AnyHUDView]
    ) {
        self.children = content()
        self.alignment = alignment
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var placed = children.enumerated().map { index, child in
            child.resolve(
                proposed: proposed,
                context: context.descending(into: child.identityToken(at: index))
            )
        }
        let size = Size(
            width: placed.reduce(0) { max($0, $1.frame.size.width) },
            height: placed.reduce(0) { max($0, $1.frame.size.height) }
        )
        for i in placed.indices {
            placed[i].frame.origin = alignment.offset(
                forChild: placed[i].frame.size, in: size
            )
        }
        return HUDNode(frame: Rect(origin: .zero, size: size), children: placed)
    }
}
