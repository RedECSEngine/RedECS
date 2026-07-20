import Geometry
import RedECS

/// Multiplies the opacity of the content's rendered output. Inside an
/// `.animated` transaction the value eases through a cache slot; otherwise
/// it applies instantly.
public struct OpacityModifier<Content: HUDView>: BuiltinHUDView {
    var value: Double?
    var fromValue: Double?
    var toValue: Double?
    public var content: Content

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        // Render-only: layout size is the content's, unaffected by opacity.
        content._size(proposed: proposed, context: context)
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var node = content._resolve(proposed: proposed, context: context)
        let applied = resolvedValue(context)
        guard applied != 1 else { return node }
        node.opacityFactor = (node.opacityFactor ?? 1) * applied
        return node
    }

    private func resolvedValue(_ context: HUDRenderContext) -> Double {
        let range = zip(fromValue, toValue).map { (from: $0.0, to: $0.1) }
        guard let animation = context.animation, let cache = context.cache else {
            return value ?? range?.to ?? 1
        }
        return cache.stepAnimation(
            key: AnimationKey(path: context.identityPath, kind: "opacity"),
            singleTarget: value,
            range: range,
            animation: animation,
            delta: context.delta
        )
    }
}

public extension HUDView {
    func opacity(_ value: Double) -> OpacityModifier<Self> {
        OpacityModifier(value: value, fromValue: nil, toValue: nil, content: self)
    }

    /// Explicit-range form for `.appear` and `.change(of:)` triggered
    /// animations, which have no previous value to animate from.
    func opacity(from: Double, to: Double) -> OpacityModifier<Self> {
        OpacityModifier(value: nil, fromValue: from, toValue: to, content: self)
    }
}
