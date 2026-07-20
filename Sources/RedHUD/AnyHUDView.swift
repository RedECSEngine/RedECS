import Geometry
import RedECS

/// Type-erased view; the currency of result builders and stack children.
public struct AnyHUDView: BuiltinHUDView {
    private let box: AnyHUDViewBox
    /// An explicit identity supplied by a data-driven container (`ForEach`),
    /// used in place of the positional index when a parent descends into
    /// this child. Nil for statically-placed views.
    var explicitIdentity: AnyHashable?

    public init<V: HUDView>(_ view: V) {
        if let erased = view as? AnyHUDView {
            self = erased
            return
        }
        self.box = HUDViewBox(view)
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        box.resolve(proposed: proposed, context: context)
    }

    /// Forwards to the boxed view's `size` so its cheap layout-only path (if
    /// any) is used, rather than the type-erased default's full resolve.
    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        box.size(proposed: proposed, context: context)
    }

    /// A copy tagged with a data-driven identity (see `explicitIdentity`).
    func identified(by id: AnyHashable) -> AnyHUDView {
        var copy = self
        copy.explicitIdentity = id
        return copy
    }

    /// The identity token a parent uses to descend into this child: the
    /// explicit id when present (`ForEach`), else the positional `index`.
    func identityToken(at index: Int) -> IdentityToken {
        explicitIdentity.map(IdentityToken.id) ?? .index(index)
    }
}

private class AnyHUDViewBox {
    func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        fatalError("abstract")
    }
    func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        fatalError("abstract")
    }
}

private final class HUDViewBox<V: HUDView>: AnyHUDViewBox {
    let view: V

    init(_ view: V) {
        self.view = view
    }

    override func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        view._resolve(proposed: proposed, context: context)
    }

    override func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        view._size(proposed: proposed, context: context)
    }
}
