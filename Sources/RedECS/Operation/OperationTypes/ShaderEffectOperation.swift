public struct ShaderEffectOperation: Operation {
    public typealias Action = Int

    public var effect: ShaderEffect
    public var animated: Bool
    public var animationDuration: Double

    public var currentTime: Double = 0
    public var duration: Double { isTimeBased ? animationDuration : Self.InstantDuration }
    public var isComplete: Bool = false

    public init(effect: ShaderEffect, animated: Bool = false, duration: Double = 1) {
        self.effect = effect
        self.animated = animated
        self.animationDuration = duration
    }

    private var isTimeBased: Bool {
        animated && effect.timeBasedCase != nil
    }

    public mutating func run(
        id: EntityId,
        state: inout BasicOperationComponentContext,
        delta: Double
    ) -> GameEffect<BasicOperationComponentContext, Action> {
        guard !isComplete else { return .none }

        guard let timeCase = isTimeBased ? effect.timeBasedCase : nil else {
            isComplete = true
            state.sprite[id]?.shader = effect
            return .none
        }

        currentTime += delta
        effect = timeCase.effect(at: currentTime)
        state.sprite[id]?.shader = effect

        if currentTime >= animationDuration {
            state.sprite[id]?.shader = nil
            isComplete = true
        }
        return .none
    }

    public mutating func reset() {
        currentTime = 0
        isComplete = false
        if let timeCase = effect.timeBasedCase {
            effect = timeCase.effect(at: 0)
        }
    }
}
