
public struct GroupOperation<GameAction: Equatable & Codable>: OperationPayload {
    public static var operationTypeId: OperationTypeId { "engine.group" }

    public var currentTime: Double = 0
    public var operations: [OperationType<GameAction>]
    
    public var currentOperationCompletionCount: Int = 0
    public var isComplete: Bool { currentOperationCompletionCount >= operations.count }
    
    public var duration: Double {
        let max = operations.max(by: { $0.duration < $1.duration })?.duration
        return max ?? Self.InstantDuration
    }
    
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
        guard !operations.isEmpty, currentOperationCompletionCount < operations.count else { return .none }
        
        var effects: [GameEffect<S, GameAction>] = []
        
        for i in 0..<operations.count {
            guard !operations[i].isComplete else { continue }
            let effect = operations[i].run(id: id, state: &state, delta: delta, registration: registration)
            effects.append(effect)
            
            if operations[i].isComplete {
                currentOperationCompletionCount += 1
            }
        }
        return .many(effects)
    }
    
    public mutating func reset() {
        currentTime = 0
        currentOperationCompletionCount = 0
        for i in 0..<operations.count {
            operations[i].reset()
        }
    }
}
