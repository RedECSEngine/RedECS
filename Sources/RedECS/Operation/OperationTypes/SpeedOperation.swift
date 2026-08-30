public struct SpeedOperation<GameAction: Equatable & Codable>: Operation {
    public typealias Action = GameAction

    public var multiplier: Double
    public var operation: OperationType<GameAction>
    public var currentTime: Double = 0

    public var duration: Double {
        let wrapped = operation.duration
        guard wrapped > 0, multiplier > 0 else { return wrapped }
        return wrapped / multiplier
    }

    public var isComplete: Bool { operation.isComplete }

    public init(multiplier: Double, operation: OperationType<GameAction>) {
        self.multiplier = multiplier
        self.operation = operation
    }

    public mutating func run<State: BasicOperationCapableState>(
        id: EntityId,
        state: inout State,
        delta: Double
    ) -> GameEffect<State, Action> {
        let effect = operation.run(id: id, state: &state, delta: delta * multiplier)
        currentTime += delta
        return effect
    }

    public mutating func reset() {
        currentTime = 0
        operation.reset()
    }
}
