import RedECS

public struct RepeatForeverOperation<GameAction: Equatable & Codable>: Operation {
    public var operation: OperationType<GameAction>
    public var currentTime: Double = 0
    public var isComplete: Bool { false }
    
    public init(
        operation: OperationType<GameAction>
    ) {
        self.operation = operation
    }
        
    public mutating func run(
        id: EntityId,
        state: inout BasicOperationComponentContext,
        delta: Double
    ) -> GameEffect<BasicOperationComponentContext, GameAction> {
        
        let effect = operation.run(id: id, state: &state, delta: delta)
        
        if operation.isComplete {
            operation.reset()
        }
        
        return effect
    }
    
    public mutating func reset() {
        currentTime = 0
        operation.reset()
    }
}
