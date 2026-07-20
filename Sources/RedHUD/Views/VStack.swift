import Geometry
import RedECS

/// Lays children out top to bottom; the vertical mirror of `HStack`.
public struct VStack: BuiltinHUDView {
    public var children: [AnyHUDView]
    public var alignment: HorizontalAlignment
    public var spacing: Double

    public init(
        alignment: HorizontalAlignment = .center,
        spacing: Double = 0,
        @HUDViewBuilder content: () -> [AnyHUDView]
    ) {
        self.children = content()
        self.alignment = alignment
        self.spacing = spacing
    }

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        stackSize(of: layoutChildren(proposed: proposed) { _, child, childProposal in
            child.size(proposed: childProposal, context: context)
        })
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var placed: [HUDNode] = []
        let sizes = layoutChildren(proposed: proposed) { index, child, childProposal in
            let node = child.resolve(
                proposed: childProposal,
                context: context.descending(into: child.identityToken(at: index))
            )
            placed.append(node)
            return node.frame.size
        }
        let size = stackSize(of: sizes)
        var y: Double = 0
        for i in placed.indices {
            placed[i].frame.origin = Point(
                x: alignment.value(in: size.width) - alignment.value(in: placed[i].frame.size.width),
                y: y
            )
            y += placed[i].frame.size.height + spacing
        }
        return HUDNode(frame: Rect(origin: .zero, size: size), children: placed)
    }

    private var totalSpacing: Double {
        spacing * Double(max(0, children.count - 1))
    }
    
    /// Visits children top-to-bottom, offering each the divided (an equal share
    /// of the remaining height) or ideal (unproposed) proposal, and collecting
    /// the size it chooses via `visit`. This proposal logic is shared by `size`
    /// (visit = measure) and `resolve` (visit = resolve + capture) so both lay
    /// out identically.
    private func layoutChildren(
        proposed: ProposedSize,
        visit: (_ index: Int, _ child: AnyHUDView, _ childProposal: ProposedSize) -> Size
    ) -> [Size] {
        guard let totalHeight = proposed.height else {
            return children.enumerated().map { index, child in
                visit(index, child, ProposedSize(width: proposed.width, height: nil))
            }
        }
        var remaining = totalHeight - totalSpacing
        var childrenLeft = children.count
        var sizes: [Size] = []
        for (index, child) in children.enumerated() {
            let share = max(0, remaining) / Double(childrenLeft)
            let s = visit(index, child, ProposedSize(width: proposed.width, height: share))
            remaining -= s.height
            childrenLeft -= 1
            sizes.append(s)
        }
        return sizes
    }

    /// The stack's size from its children's sizes: widest child × summed heights.
    private func stackSize(of childSizes: [Size]) -> Size {
        Size(
            width: childSizes.reduce(0) { max($0, $1.width) },
            height: childSizes.reduce(0) { $0 + $1.height } + totalSpacing
        )
    }
}
