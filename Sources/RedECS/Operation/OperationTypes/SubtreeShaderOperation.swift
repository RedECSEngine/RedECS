public struct SubtreeShaderOperation: Operation {
    public typealias Action = Int

    public var effect: ShaderEffect.TimeBased
    public var animationDuration: Double
    public var reversed: Bool

    public var currentTime: Double = 0
    public var duration: Double { animationDuration }
    public var isComplete: Bool = false

    public init(
        effect: ShaderEffect.TimeBased,
        duration: Double,
        reversed: Bool = false
    ) {
        self.effect = effect
        self.animationDuration = duration
        self.reversed = reversed
    }

    public mutating func run(
        id: EntityId,
        state: inout BasicOperationComponentContext,
        delta: Double
    ) -> GameEffect<BasicOperationComponentContext, Action> {
        guard !isComplete else { return .none }
        currentTime += delta

        if currentTime >= animationDuration {
            isComplete = true
            for target in subtree(of: id, in: state) {
                state.sprite[target]?.shader = nil
            }
            return .none
        }

        let progress = clamped(animationDuration > 0 ? currentTime / animationDuration : 1)
        let shader = effect.effect(at: reversed ? clamped(1 - progress) : progress)
        for target in subtree(of: id, in: state) {
            state.sprite[target]?.shader = shader
        }
        return .none
    }

    public mutating func reset() {
        currentTime = 0
        isComplete = false
    }

    private func subtree(of id: EntityId, in state: BasicOperationComponentContext) -> [EntityId] {
        [id] + state.entities.descendants(of: id)
    }

    private func clamped(_ time: Double) -> Double {
        min(max(time, 0), 0.999)
    }
}
