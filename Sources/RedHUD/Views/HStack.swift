import Geometry
import RedECS

/// Lays children out left to right. The proposed width (minus spacing) is
/// divided equally among the children not yet sized; each child then keeps
/// whatever width it chooses and the remainder is redistributed. No
/// flexibility ranking yet — that arrives with Spacer/flexible frames.
public struct HStack: BuiltinHUDView {
    public var children: [AnyHUDView]
    public var alignment: VerticalAlignment
    public var spacing: Double

    public init(
        alignment: VerticalAlignment = .center,
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
        var x: Double = 0
        for i in placed.indices {
            placed[i].frame.origin = Point(
                x: x,
                y: alignment.value(in: size.height) - alignment.value(in: placed[i].frame.size.height)
            )
            x += placed[i].frame.size.width + spacing
        }
        return HUDNode(frame: Rect(origin: .zero, size: size), children: placed)
    }

    private var totalSpacing: Double {
        spacing * Double(max(0, children.count - 1))
    }
    
    /// Visits children left-to-right, offering each the divided (an equal share
    /// of the remaining width) or ideal (unproposed) proposal, and collecting
    /// the size it chooses via `visit`. Shared by `size` (visit = measure) and
    /// `resolve` (visit = resolve + capture) so both lay out identically.
    private func layoutChildren(
        proposed: ProposedSize,
        visit: (_ index: Int, _ child: AnyHUDView, _ childProposal: ProposedSize) -> Size
    ) -> [Size] {
        guard let totalWidth = proposed.width else {
            return children.enumerated().map { index, child in
                visit(index, child, ProposedSize(width: nil, height: proposed.height))
            }
        }
        var remaining = totalWidth - totalSpacing
        var childrenLeft = children.count
        var sizes: [Size] = []
        for (index, child) in children.enumerated() {
            let share = max(0, remaining) / Double(childrenLeft)
            let s = visit(index, child, ProposedSize(width: share, height: proposed.height))
            remaining -= s.width
            childrenLeft -= 1
            sizes.append(s)
        }
        return sizes
    }

    /// The stack's size from its children's sizes: summed widths × tallest child.
    private func stackSize(of childSizes: [Size]) -> Size {
        Size(
            width: childSizes.reduce(0) { $0 + $1.width } + totalSpacing,
            height: childSizes.reduce(0) { max($0, $1.height) }
        )
    }
}
