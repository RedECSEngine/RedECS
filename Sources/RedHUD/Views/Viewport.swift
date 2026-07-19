import Geometry
import RedECS

/// The HUD root when a single frame mixes spaces or needs explicit layering.
/// It fills the proposed viewport and overlays its `Layer`s; the reducer gives
/// the whole tree a base z above all world drawing, so every HUD group paints
/// over the scene. Layers are drawn in declaration order (see `Layer`).
///
///     Viewport {
///         Layer { ScreenSpace { Pin(.topLeading) { … } } }   // under
///         Layer { WorldSpace  { WorldPosition(x:, y:) { … } } } // over
///     }
///
/// Simple screen-only HUDs don't need it — a bare `ScreenSpace { … }` (or even
/// a `VStack`) is still a valid root.
public struct Viewport: BuiltinHUDView {
    public var layers: [AnyHUDView]

    public init(@HUDViewBuilder content: () -> [AnyHUDView]) {
        self.layers = content()
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        resolveOverlaid(children: layers, proposed: proposed, context: context)
    }
}

/// One paint band of a `Viewport`. Layers overlay at the same origin and are
/// drawn in declaration order — the first `Layer` paints under later ones —
/// because the reducer assigns z in tree order. Holds a space (`ScreenSpace`/
/// `WorldSpace`) or any content; a home for future per-layer opacity/clipping.
public struct Layer: BuiltinHUDView {
    public var content: [AnyHUDView]

    public init(@HUDViewBuilder content: () -> [AnyHUDView]) {
        self.content = content()
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        resolveOverlaid(children: content, proposed: proposed, context: context)
    }
}

/// Resolves children at the incoming proposal and stacks them on a shared
/// origin (each places itself). Fills the proposal so a `Viewport` root spans
/// the viewport; paint/z order follows child order.
private func resolveOverlaid(
    children: [AnyHUDView],
    proposed: ProposedSize,
    context: HUDRenderContext
) -> HUDNode {
    let size = proposed.orDefault()
    let placed = children.enumerated().map { index, child in
        child.resolve(proposed: ProposedSize(size), context: context.descending(into: index))
    }
    return HUDNode(frame: Rect(origin: .zero, size: size), children: placed)
}
