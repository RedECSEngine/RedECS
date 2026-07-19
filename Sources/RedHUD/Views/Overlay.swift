import Geometry
import RedECS

/// Layers `overlay` on top of `content` without affecting layout: the base
/// content is sized by the incoming proposal and the modifier reports *its*
/// size, then the overlay is offered that size and aligned within it
/// (default centered). Unlike `ZStack`, the overlay never enlarges the
/// result — it is measured against, and clipped to nothing beyond, the base.
public struct Overlay<Content: HUDView, OverlayContent: HUDView>: BuiltinHUDView {
    public var content: Content
    public var overlay: OverlayContent
    public var alignment: Alignment

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var base = content._resolve(proposed: proposed, context: context.descending(into: 0))
        let size = base.frame.size
        base.frame.origin = .zero
        var over = overlay._resolve(
            proposed: ProposedSize(size),
            context: context.descending(into: 1)
        )
        over.frame.origin = alignment.offset(forChild: over.frame.size, in: size)
        return HUDNode(frame: Rect(origin: .zero, size: size), children: [base, over])
    }
}

public extension HUDView {
    /// Places builder content on top of this view, aligned within its bounds
    /// (default centered), without changing this view's size. Multiple
    /// overlay views are layered in an implicit `ZStack`.
    func overlay(
        alignment: Alignment = .center,
        @HUDViewBuilder content: () -> [AnyHUDView]
    ) -> Overlay<Self, AnyHUDView> {
        let views = content()
        let over = views.count == 1 ? views[0] : AnyHUDView(ZStack { views })
        return Overlay(content: self, overlay: over, alignment: alignment)
    }
}
