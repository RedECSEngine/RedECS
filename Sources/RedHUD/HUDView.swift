import Geometry
import RedECS

/// A composable piece of HUD layout. Custom views compose others via `body`;
/// leaf views conform to `BuiltinHUDView` instead and never call `body`.
public protocol HUDView {
    associatedtype Body: HUDView
    var body: Body { get }
}

/// A leaf (or container) view that participates in layout directly: given a
/// proposal it resolves to a `HUDNode` sized to its answer, containing its
/// own draw output (local space, origin at its top-left, y-down viewport
/// points) and its placed children.
///
/// Invariant: a view always resolves to the size it would report for that
/// proposal — parents place children at exactly the size the child chose.
protocol BuiltinHUDView: HUDView where Body == Never {
    func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode
    func size(proposed: ProposedSize, context: HUDRenderContext) -> Size
}

extension BuiltinHUDView {
    func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        resolve(proposed: proposed, context: context).frame.size
    }
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
    func _resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var node: HUDNode
        if let builtin = self as? any BuiltinHUDView {
            node = builtin.resolve(proposed: proposed, context: context)
        } else {
            node = body._resolve(proposed: proposed, context: context)
        }
        // Stamp the resolve-time identity so hit testing reports the same
        // path that keys animation (modifiers share their content's path;
        // re-stamping it is a no-op).
        node.identity = context.identityPath
        return node
    }

    /// Dispatches `size` to a builtin's (possibly cheap) implementation, or a composite view's `body`.
    func _size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        if let builtin = self as? any BuiltinHUDView {
            return builtin.size(proposed: proposed, context: context)
        }
        return body._size(proposed: proposed, context: context)
    }
}

public extension HUDView {
    /// The size this view resolves to for a proposal — cheap where the view
    /// provides a layout-only `size`, else a full `resolve`. A convenience over
    /// `resolve` for measurement and tests.
    func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        _size(proposed: proposed, context: context)
    }
}
