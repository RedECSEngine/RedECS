import Geometry
import RedECS

/// Insets the content by `length` on all four sides: the proposal shrinks by
/// the insets, and the reported size grows back around whatever the content
/// chooses.
public struct Padding<Content: HUDView>: BuiltinHUDView {
    public var length: Double
    public var content: Content

    /// The proposal handed to the content: the parent's, shrunk by the insets.
    /// Shared by `size` and `resolve`.
    private func contentProposal(_ proposed: ProposedSize) -> ProposedSize {
        ProposedSize(
            width: proposed.width.map { max(0, $0 - length * 2) },
            height: proposed.height.map { max(0, $0 - length * 2) }
        )
    }

    /// The padded size: the content's size grown by the insets on all sides.
    private func paddedSize(contentSize: Size) -> Size {
        Size(width: contentSize.width + length * 2, height: contentSize.height + length * 2)
    }

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        paddedSize(contentSize: content._size(proposed: contentProposal(proposed), context: context))
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var child = content._resolve(proposed: contentProposal(proposed), context: context.descending(into: 0))
        child.frame.origin = Point(x: length, y: length)
        return HUDNode(
            frame: Rect(origin: .zero, size: paddedSize(contentSize: child.frame.size)),
            children: [child]
        )
    }
}

public extension HUDView {
    func padding(_ length: Double = 8) -> Padding<Self> {
        Padding(length: length, content: self)
    }
}
