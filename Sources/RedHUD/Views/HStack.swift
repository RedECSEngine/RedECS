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
        let sizes = layout(proposed: proposed, context: context)
        return Size(
            width: sizes.reduce(0) { $0 + $1.width } + totalSpacing,
            height: sizes.reduce(0) { max($0, $1.height) }
        )
    }

    public func render(context: HUDRenderContext, size: Size) -> [RenderGroup] {
        let sizes = layout(proposed: ProposedSize(size), context: context)
        var groups: [RenderGroup] = []
        var x: Double = 0
        for (child, childSize) in zip(children, sizes) {
            let offset = Point(
                x: x,
                y: alignment.value(in: size.height) - alignment.value(in: childSize.height)
            )
            groups.append(contentsOf: child.render(context: context, size: childSize)
                .map { $0.reparented(by: offset) })
            x += childSize.width + spacing
        }
        return groups
    }

    private var totalSpacing: Double {
        spacing * Double(max(0, children.count - 1))
    }

    private func layout(proposed: ProposedSize, context: HUDRenderContext) -> [Size] {
        guard let totalWidth = proposed.width else {
            // No proposal along the major axis: every child gets its ideal.
            return children.map {
                $0.size(proposed: ProposedSize(width: nil, height: proposed.height), context: context)
            }
        }
        var remaining = totalWidth - totalSpacing
        var childrenLeft = children.count
        var sizes: [Size] = []
        for child in children {
            let share = max(0, remaining) / Double(childrenLeft)
            let childSize = child.size(
                proposed: ProposedSize(width: share, height: proposed.height),
                context: context
            )
            sizes.append(childSize)
            remaining -= childSize.width
            childrenLeft -= 1
        }
        return sizes
    }
}
