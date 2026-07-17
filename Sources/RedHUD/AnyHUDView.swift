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

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        box.size(proposed: proposed, context: context)
    }

    public func render(context: HUDRenderContext, size: Size) -> [RenderGroup] {
        box.render(context: context, size: size)
    }
}

private class AnyHUDViewBox {
    func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        fatalError("abstract")
    }
    func render(context: HUDRenderContext, size: Size) -> [RenderGroup] {
        fatalError("abstract")
    }
}

private final class HUDViewBox<V: HUDView>: AnyHUDViewBox {
    let view: V

    init(_ view: V) {
        self.view = view
    }

    override func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        view._size(proposed: proposed, context: context)
    }

    override func render(context: HUDRenderContext, size: Size) -> [RenderGroup] {
        view._render(context: context, size: size)
    }
}
