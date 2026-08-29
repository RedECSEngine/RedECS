
public struct SequenceOperation<GameAction: Equatable & Codable>: OperationPayload {
    public static var operationTypeId: OperationTypeId { "engine.sequence" }

    public var currentTime: Double = 0
    public var operations: [OperationType<GameAction>]
    
    public var duration: Double {
        if operations.isEmpty {
            return Self.InstantDuration
        } else {
            return operations.reduce(0) { $0 + $1.duration }
        }
    }
    
    public var currentOperationIndex: Int = 0
    public var isComplete: Bool { currentOperationIndex >= operations.count }
    
    public init(
        operations: [OperationType<GameAction>]
    ) {
        self.operations = operations
    }
        
    public mutating func run<S: OperationCapableGameState>(
        id: EntityId,
        state: inout S,
        delta: Double,
        registration: GameRegistration<S, GameAction>
    ) -> GameEffect<S, GameAction> where S.GameAction == GameAction {
        guard !operations.isEmpty, currentOperationIndex < operations.count else { return .none }
        let effect = operations[currentOperationIndex].run(id: id, state: &state, delta: delta, registration: registration)
        if operations[currentOperationIndex].isComplete {
            currentOperationIndex += 1
        }
        return effect
    }
    
    public mutating func reset() {
        currentTime = 0
        currentOperationIndex = 0
        for i in 0..<operations.count {
            operations[i].reset()
        }
    }
}
