import RedECS

public struct RepeatOperation<GameAction: Equatable & Codable>: Operation {
    public enum Strategy: Equatable, Codable {
        case forever
        case times(Int)
    }
    
    public var strategy: Strategy
    public var operation: OperationType<GameAction>
    public var totalTime: Double = 0
    public var currentTime: Double = 0
    public var isComplete: Bool = false
    
    public var duration: Double {
        switch strategy {
        case .forever:
            return Self.InfiniteDuration
        case .times(let times):
            return operation.duration * Double(times)
        }
    }
    
    public init(
        strategy: Strategy,
        operation: OperationType<GameAction>
    ) {
        self.strategy = strategy
        self.operation = operation
    }
        
    public mutating func run(
        id: EntityId,
        state: inout BasicOperationComponentContext,
        delta: Double
    ) -> GameEffect<BasicOperationComponentContext, GameAction> {
        
        let effect = operation.run(id: id, state: &state, delta: delta)
        
        currentTime += delta
        totalTime += delta
        
        switch strategy {
        case .forever: break
        case .times(let count):
            if Int(totalTime / currentTime) >= count {
               isComplete = true
            }
        }
        
        if operation.isComplete {
            currentTime = 0
            operation.reset()
        }
        
        return effect
    }
    
    public mutating func reset() {
        currentTime = 0
        totalTime = 0
        operation.reset()
        isComplete = false
    }
}
