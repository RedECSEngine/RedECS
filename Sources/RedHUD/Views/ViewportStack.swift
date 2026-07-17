import Geometry
import RedECS

/// One corner/edge/center-pinned entry in a `ViewportStack`. Multiple views
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
public enum ViewportStackBuilder {
    public static func buildExpression(_ pin: Pin) -> [Pin] { [pin] }
    public static func buildBlock(_ components: [Pin]...) -> [Pin] { components.flatMap { $0 } }
    public static func buildOptional(_ component: [Pin]?) -> [Pin] { component ?? [] }
    public static func buildEither(first component: [Pin]) -> [Pin] { component }
    public static func buildEither(second component: [Pin]) -> [Pin] { component }
    public static func buildArray(_ components: [[Pin]]) -> [Pin] { components.flatMap { $0 } }
}

/// The HUD root: fills whatever it is proposed (normally the viewport) and
/// pins each entry's content to its own corner, edge, or center. Later
/// entries paint over earlier ones.
public struct ViewportStack: BuiltinHUDView {
    public var pins: [Pin]

    public init(@ViewportStackBuilder content: () -> [Pin]) {
        self.pins = content()
    }

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        proposed.orDefault()
    }

    public func render(context: HUDRenderContext, size: Size) -> [RenderGroup] {
        pins.flatMap { pin -> [RenderGroup] in
            let childSize = pin.content.size(proposed: ProposedSize(size), context: context)
            let offset = pin.alignment.offset(forChild: childSize, in: size)
            return pin.content.render(context: context, size: childSize)
                .map { $0.reparented(by: offset) }
        }
    }
}
