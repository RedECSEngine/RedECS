import Geometry
import GeometryAlgorithms
import RedECS

/// Scales the content's rendered output about its center. Render-only:
/// layout size and hit geometry are unaffected (SwiftUI parity). Inside an
/// `.animated` transaction the scale eases through a cache slot; otherwise
/// it applies instantly.
public struct ScaleEffect<Content: HUDView>: BuiltinHUDView {
    /// Single-value form: the target, animated on `.targetChange`.
    var scale: Double?
    /// Explicit range form, required by `.appear` and `.change(of:)`.
    var fromScale: Double?
    var toScale: Double?
    public var content: Content

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var node = content._resolve(proposed: proposed, context: context)
        let applied = resolvedValue(context)
        guard applied != 1 else { return node }
        let center = Point(
            x: node.frame.size.width / 2,
            y: node.frame.size.height / 2
        )
        let scaling = Matrix3.identity
            .translatedBy(tx: center.x, ty: center.y)
            .scaledBy(sx: applied, sy: applied)
            .translatedBy(tx: -center.x, ty: -center.y)
        node.transform = node.transform.map { .multiply(scaling, $0) } ?? scaling
        return node
    }

    private func resolvedValue(_ context: HUDRenderContext) -> Double {
        let range = zip(fromScale, toScale).map { (from: $0.0, to: $0.1) }
        guard let animation = context.animation, let cache = context.cache else {
            return scale ?? range?.to ?? 1
        }
        return cache.stepAnimation(
            key: AnimationKey(path: context.identityPath, kind: "scale"),
            singleTarget: scale,
            range: range,
            animation: animation,
            delta: context.delta
        )
    }
}

public extension HUDView {
    /// Scales rendered output about the content's center.
    func scaleEffect(_ scale: Double) -> ScaleEffect<Self> {
        ScaleEffect(scale: scale, fromScale: nil, toScale: nil, content: self)
    }

    /// Explicit-range form for `.appear` and `.change(of:)` triggered
    /// animations, which have no previous value to animate from.
    func scaleEffect(from: Double, to: Double) -> ScaleEffect<Self> {
        ScaleEffect(scale: nil, fromScale: from, toScale: to, content: self)
    }
}

/// `zip` for optionals: both or nothing.
func zip<A, B>(_ a: A?, _ b: B?) -> (A, B)? {
    guard let a = a, let b = b else { return nil }
    return (a, b)
}
