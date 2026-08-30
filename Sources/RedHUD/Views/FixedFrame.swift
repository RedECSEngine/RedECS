import Geometry
import RedECS

/// Fixes one or both dimensions and aligns the content inside the frame.
/// A nil dimension proposes the parent's proposal through to the content
/// and adopts whatever size the content chooses along that axis.
public struct FixedFrame<Content: HUDView>: BuiltinHUDView {
    public var width: Double?
    public var height: Double?
    public var alignment: Alignment
    public var content: Content

    /// The proposal passed through to the content: a fixed axis overrides the
    /// parent's; a nil axis passes through. Shared by `size` and `resolve`.
    private func contentProposal(_ proposed: ProposedSize) -> ProposedSize {
        ProposedSize(width: width ?? proposed.width, height: height ?? proposed.height)
    }

    /// The frame's size given the content's chosen size: a fixed axis wins, a
    /// nil axis adopts the content's. Shared by `size` and `resolve`.
    private func frameSize(contentSize: Size) -> Size {
        Size(width: width ?? contentSize.width, height: height ?? contentSize.height)
    }

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        frameSize(contentSize: content._size(proposed: contentProposal(proposed), context: context))
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var child = content._resolve(proposed: contentProposal(proposed), context: context.descending(into: 0))
        let size = frameSize(contentSize: child.frame.size)
        child.frame.origin = alignment.offset(forChild: child.frame.size, in: size)
        return HUDNode(frame: Rect(origin: .zero, size: size), children: [child])
    }
}

public extension HUDView {
    func frame(
        width: Double? = nil,
        height: Double? = nil,
        alignment: Alignment = .center
    ) -> FixedFrame<Self> {
        FixedFrame(width: width, height: height, alignment: alignment, content: self)
    }
}
