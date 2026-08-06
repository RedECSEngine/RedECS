public struct PlaySoundOperation<GameAction: Equatable & Codable>: Operation {
    public typealias Action = GameAction

    public var duration: Double = 0
    public var currentTime: Double = 0
    public var isComplete: Bool = false

    public var sound: SoundId

    public init(sound: SoundId) {
        self.sound = sound
    }

    public mutating func run(id: EntityId, state: inout BasicOperationComponentContext, delta: Double) -> GameEffect<BasicOperationComponentContext, Action> {
        isComplete = true
        return .system(.playSound(sound))
    }

    public mutating func reset() {
        isComplete = false
    }
}
