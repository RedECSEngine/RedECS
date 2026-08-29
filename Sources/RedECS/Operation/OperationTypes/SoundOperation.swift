public struct SoundOperation<GameAction: Equatable & Codable>: OperationPayload {
    public static var operationTypeId: OperationTypeId { "engine.sound" }


    public enum Strategy: Equatable, Codable {
        case play(SoundId)
        case stop(SoundId)
        case stopAll
    }

    public var duration: Double = 0
    public var currentTime: Double = 0
    public var isComplete: Bool = false

    public var strategy: Strategy

    public init(strategy: Strategy) {
        self.strategy = strategy
    }

    public mutating func run<S: GameState>(id: EntityId) -> GameEffect<S, GameAction> {
        isComplete = true
        switch strategy {
        case .play(let sound):
            return .system(.playSound(sound))
        case .stop(let sound):
            return .system(.stopSound(sound))
        case .stopAll:
            return .system(.stopAllSounds)
        }
    }

    public mutating func reset() {
        isComplete = false
    }
}
