import Geometry
import RedECS

/// A composable piece of HUD layout. Custom views compose others via `body`;
/// leaf views conform to `BuiltinHUDView` instead and never call `body`.
public protocol HUDView {
    associatedtype Body: HUDView
    var body: Body { get }
}

/// A leaf (or container) view that participates in layout directly:
/// it answers a proposed size and emits render groups in its own local
/// space, with the origin at its top-left corner (y-down, viewport points).
public protocol BuiltinHUDView: HUDView where Body == Never {
    func size(proposed: ProposedSize, context: HUDRenderContext) -> Size
    func render(context: HUDRenderContext, size: Size) -> [RenderGroup]
}

extension Never: HUDView {
    public typealias Body = Never
}

public extension HUDView where Body == Never {
    var body: Never {
        fatalError("body of a BuiltinHUDView must never be called")
    }
}

extension HUDView {
    func _size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        if let builtin = self as? any BuiltinHUDView {
            return builtin.size(proposed: proposed, context: context)
        }
        return body._size(proposed: proposed, context: context)
    }

    func _render(context: HUDRenderContext, size: Size) -> [RenderGroup] {
        if let builtin = self as? any BuiltinHUDView {
            return builtin.render(context: context, size: size)
        }
        return body._render(context: context, size: size)
    }
}
