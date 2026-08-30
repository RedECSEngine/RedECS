import Geometry
import RedECS

/// One corner/edge/center-pinned entry in a `ScreenSpace`. Multiple views
/// in the builder are implicitly wrapped in a `VStack`.
public struct Pin {
    public var alignment: Alignment
    public var content: AnyHUDView

    public init(_ alignment: Alignment, @HUDViewBuilder content: () -> [AnyHUDView]) {
        self.alignment = alignment
        let views = content()
        if views.count == 1 {
            self.content = views[0]
        } else {
            self.content = AnyHUDView(VStack { views })
        }
    }
}

@resultBuilder
public enum ScreenSpaceBuilder {
    public static func buildExpression(_ pin: Pin) -> [Pin] { [pin] }
    public static func buildBlock(_ components: [Pin]...) -> [Pin] { components.flatMap { $0 } }
    public static func buildOptional(_ component: [Pin]?) -> [Pin] { component ?? [] }
    public static func buildEither(first component: [Pin]) -> [Pin] { component }
    public static func buildEither(second component: [Pin]) -> [Pin] { component }
    public static func buildArray(_ components: [[Pin]]) -> [Pin] { components.flatMap { $0 } }
}

/// A screen-space layer: fills whatever it is proposed (normally the viewport)
/// and pins each entry's content to its own corner, edge, or center. Leaves
/// stamp `.screen` (the context default), so its output maps straight to
/// viewport points regardless of the camera. Later entries paint over earlier
/// ones. It is *positional*, not a flow stack — hence `Space`, not `Stack`.
public struct ScreenSpace: BuiltinHUDView {
    public var pins: [Pin]

    public init(@ScreenSpaceBuilder content: () -> [Pin]) {
        self.pins = content()
    }

    // A screen-space root fills its proposal. Never measured in practice (it's
    // the HUD root, not a lazy row); provided for consistency so `size` never
    // falls back to a full resolve.
    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        proposed.orDefault()
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        let size = size(proposed: proposed, context: context)
        let placed = pins.enumerated().map { index, pin -> HUDNode in
            var child = pin.content.resolve(
                proposed: ProposedSize(size),
                context: context.descending(into: index)
            )
            child.frame.origin = pin.alignment.offset(forChild: child.frame.size, in: size)
            return child
        }
        return HUDNode(frame: Rect(origin: .zero, size: size), children: placed)
    }
}
