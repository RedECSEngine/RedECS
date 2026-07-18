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

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var child = content._resolve(
            proposed: ProposedSize(
                width: width ?? proposed.width,
                height: height ?? proposed.height
            ),
            context: context.descending(into: 0)
        )
        let size = Size(
            width: width ?? child.frame.size.width,
            height: height ?? child.frame.size.height
        )
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
