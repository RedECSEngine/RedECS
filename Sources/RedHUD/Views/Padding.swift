import Geometry
import RedECS

/// Insets the content by `length` on all four sides: the proposal shrinks by
/// the insets, and the reported size grows back around whatever the content
/// chooses.
public struct Padding<Content: HUDView>: BuiltinHUDView {
    public var length: Double
    public var content: Content

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var child = content._resolve(
            proposed: ProposedSize(
                width: proposed.width.map { max(0, $0 - length * 2) },
                height: proposed.height.map { max(0, $0 - length * 2) }
            ),
            context: context.descending(into: 0)
        )
        child.frame.origin = Point(x: length, y: length)
        return HUDNode(
            frame: Rect(
                origin: .zero,
                size: Size(
                    width: child.frame.size.width + length * 2,
                    height: child.frame.size.height + length * 2
                )
            ),
            children: [child]
        )
    }
}

public extension HUDView {
    func padding(_ length: Double = 8) -> Padding<Self> {
        Padding(length: length, content: self)
    }
}
