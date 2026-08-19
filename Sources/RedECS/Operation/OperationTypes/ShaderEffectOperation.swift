public struct ShaderEffectOperation: OperationPayload {
    public static var operationTypeId: OperationTypeId { "engine.shaderEffect" }


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

    public mutating func run<S: SpriteProviding>(
        id: EntityId,
        state: inout S,
        delta: Double
    ) {
        guard !isComplete else { return }

        guard let timeCase = isTimeBased ? effect.timeBasedCase : nil else {
            isComplete = true
            state.sprite[id]?.shader = effect
            return
        }

        currentTime += delta
        effect = timeCase.effect(at: currentTime)
        state.sprite[id]?.shader = effect

        if currentTime >= animationDuration {
            state.sprite[id]?.shader = nil
            isComplete = true
        }
    }

    public mutating func reset() {
        currentTime = 0
        isComplete = false
        if let timeCase = effect.timeBasedCase {
            effect = timeCase.effect(at: 0)
        }
    }
}

private extension ShaderEffect {
    var timeBasedCase: TimeBasedCase? {
        switch self {
        case .ripple:     return .ripple
        case .waves:      return .waves
        case .liquid:     return .liquid
        case .turnOff:    return .turnOff
        case .splitRows:  return .splitRows
        case .splitCols:  return .splitCols
        case .shaky:      return .shaky
        case .shakyTiles: return .shakyTiles
        case .shuffle:    return .shuffle
        case .tint, .paletteRemap, .custom:
            return nil
        }
    }

    enum TimeBasedCase {
        case ripple, waves, liquid, turnOff, splitRows, splitCols
        case shaky, shakyTiles, shuffle

        func effect(at time: Double) -> ShaderEffect {
            switch self {
            case .ripple:     return .ripple(time: time)
            case .waves:      return .waves(time: time)
            case .liquid:     return .liquid(time: time)
            case .turnOff:    return .turnOff(time: time)
            case .splitRows:  return .splitRows(time: time)
            case .splitCols:  return .splitCols(time: time)
            case .shaky:      return .shaky(time: time)
            case .shakyTiles: return .shakyTiles(time: time)
            case .shuffle:    return .shuffle(time: time)
            }
        }
    }
}
