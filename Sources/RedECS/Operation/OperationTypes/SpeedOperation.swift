public struct SpeedOperation<GameAction: Equatable & Codable>: OperationPayload {
    public static var operationTypeId: OperationTypeId { "engine.speed" }


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

    public mutating func run<S: OperationCapableGameState>(
        id: EntityId,
        state: inout S,
        delta: Double,
        registration: GameRegistration<S, GameAction>
    ) -> GameEffect<S, GameAction> where S.GameAction == GameAction {
        let effect = operation.run(id: id, state: &state, delta: delta * multiplier, registration: registration)
        currentTime += delta
        return effect
    }

    public mutating func reset() {
        currentTime = 0
        operation.reset()
    }
}
