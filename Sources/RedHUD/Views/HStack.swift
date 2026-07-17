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

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var placed: [HUDNode] = []
        if let totalWidth = proposed.width {
            var remaining = totalWidth - totalSpacing
            var childrenLeft = children.count
            for child in children {
                let share = max(0, remaining) / Double(childrenLeft)
                let node = child.resolve(
                    proposed: ProposedSize(width: share, height: proposed.height),
                    context: context
                )
                remaining -= node.frame.size.width
                childrenLeft -= 1
                placed.append(node)
            }
        } else {
            // No proposal along the major axis: every child gets its ideal.
            placed = children.map {
                $0.resolve(proposed: ProposedSize(width: nil, height: proposed.height), context: context)
            }
        }

        let size = Size(
            width: placed.reduce(0) { $0 + $1.frame.size.width } + totalSpacing,
            height: placed.reduce(0) { max($0, $1.frame.size.height) }
        )
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
}
