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

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        let childSize = content._size(
            proposed: ProposedSize(
                width: width ?? proposed.width,
                height: height ?? proposed.height
            ),
            context: context
        )
        return Size(
            width: width ?? childSize.width,
            height: height ?? childSize.height
        )
    }

    public func render(context: HUDRenderContext, size: Size) -> [RenderGroup] {
        let childSize = content._size(proposed: ProposedSize(size), context: context)
        let offset = alignment.offset(forChild: childSize, in: size)
        return content._render(context: context, size: childSize)
            .map { $0.reparented(by: offset) }
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
