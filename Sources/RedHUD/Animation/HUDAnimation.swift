import Geometry
import RedECS

public enum LoopStrategy: Equatable, Sendable {
    /// Jump back and replay start → target each leg.
    case restart
    /// Reverse direction each leg.
    case pingPong
}

public enum Repetition: Equatable, Sendable {
    /// Play once and settle at the target.
    case once
    /// N traversals of the duration. With `pingPong` an even count ends at
    /// the start value, an odd count at the target; `restart` always ends
    /// at the target.
    case count(Int, strategy: LoopStrategy)
    case forever(strategy: LoopStrategy)
}

public enum AnimationTrigger: Equatable {
    /// Animate whenever the driving value changes (single-value modifier
    /// form; the range is implicit: previous value → new value). The
    /// initial appearance installs at the target without animating.
    case targetChange
    /// Start at node birth. Requires the explicit `from:to:` modifier form.
    case appear
    /// Replay whenever this value changes; silent at birth. Requires the
    /// explicit `from:to:` modifier form.
    case change(of: AnyHashable)
}

/// An animation transaction flowing down the context: animatable modifiers
/// (`scaleEffect`, `opacity`) between `.animated` and the leaves ease their
/// values through cache slots instead of applying them instantly.
public struct HUDAnimation: Equatable {
    public var duration: Double
    public var timing: TimingFunction
    public var repeats: Repetition
    public var trigger: AnimationTrigger

    public init(
        duration: Double,
        timing: TimingFunction = .linear,
        repeats: Repetition = .once,
        trigger: AnimationTrigger = .targetChange
    ) {
        self.duration = duration
        self.timing = timing
        self.repeats = repeats
        self.trigger = trigger
    }
}

/// Context-setting wrapper: everything it contains resolves with the
/// transaction available. The same species of modifier as `.font()`.
public struct AnimatedModifier<Content: HUDView>: BuiltinHUDView {
    public var animation: HUDAnimation
    public var content: Content

    public func size(proposed: ProposedSize, context: HUDRenderContext) -> Size {
        // Animation is render-only; layout size is the content's.
        content._size(proposed: proposed, context: context)
    }

    public func resolve(proposed: ProposedSize, context: HUDRenderContext) -> HUDNode {
        var context = context
        context.animation = animation
        return content._resolve(proposed: proposed, context: context)
    }
}

public extension HUDView {
    func animated(
        duration: Double,
        timing: TimingFunction = .linear,
        repeats: Repetition = .once,
        on trigger: AnimationTrigger = .targetChange
    ) -> AnimatedModifier<Self> {
        AnimatedModifier(
            animation: HUDAnimation(
                duration: duration,
                timing: timing,
                repeats: repeats,
                trigger: trigger
            ),
            content: self
        )
    }
}
