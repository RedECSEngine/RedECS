import Geometry
import RedECS

/// Type-erased view; the currency of result builders and stack children.
public struct AnyHUDView: BuiltinHUDView {
    private let box: AnyHUDViewBox

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
}

private class AnyHUDViewBox {
    func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
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
}
