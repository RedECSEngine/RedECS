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
        let sizes = layout(proposed: proposed, context: context)
        return Size(
            width: sizes.reduce(0) { max($0, $1.width) },
            height: sizes.reduce(0) { $0 + $1.height } + totalSpacing
        )
    }

    public func render(context: HUDRenderContext, size: Size) -> [RenderGroup] {
        let sizes = layout(proposed: ProposedSize(size), context: context)
        var groups: [RenderGroup] = []
        var y: Double = 0
        for (child, childSize) in zip(children, sizes) {
            let offset = Point(
                x: alignment.value(in: size.width) - alignment.value(in: childSize.width),
                y: y
            )
            groups.append(contentsOf: child.render(context: context, size: childSize)
                .map { $0.reparented(by: offset) })
            y += childSize.height + spacing
        }
        return groups
    }

    private var totalSpacing: Double {
        spacing * Double(max(0, children.count - 1))
    }

    private func layout(proposed: ProposedSize, context: HUDRenderContext) -> [Size] {
        guard let totalHeight = proposed.height else {
            return children.map {
                $0.size(proposed: ProposedSize(width: proposed.width, height: nil), context: context)
            }
        }
        var remaining = totalHeight - totalSpacing
        var childrenLeft = children.count
        var sizes: [Size] = []
        for child in children {
            let share = max(0, remaining) / Double(childrenLeft)
            let childSize = child.size(
                proposed: ProposedSize(width: proposed.width, height: share),
                context: context
            )
            sizes.append(childSize)
            remaining -= childSize.height
            childrenLeft -= 1
        }
        return sizes
    }
}
