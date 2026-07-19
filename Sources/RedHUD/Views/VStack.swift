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

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var placed: [HUDNode] = []
        if let totalHeight = proposed.height {
            var remaining = totalHeight - totalSpacing
            var childrenLeft = children.count
            for (index, child) in children.enumerated() {
                let share = max(0, remaining) / Double(childrenLeft)
                let node = child.resolve(
                    proposed: ProposedSize(width: proposed.width, height: share),
                    context: context.descending(into: child.identityToken(at: index))
                )
                remaining -= node.frame.size.height
                childrenLeft -= 1
                placed.append(node)
            }
        } else {
            placed = children.enumerated().map { index, child in
                child.resolve(
                    proposed: ProposedSize(width: proposed.width, height: nil),
                    context: context.descending(into: child.identityToken(at: index))
                )
            }
        }

        let size = Size(
            width: placed.reduce(0) { max($0, $1.frame.size.width) },
            height: placed.reduce(0) { $0 + $1.frame.size.height } + totalSpacing
        )
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
}
