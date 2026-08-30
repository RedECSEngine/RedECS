
public struct CallOperation<GameAction: Equatable & Codable>: Operation {
    public var currentTime: Double = 0
    public var duration: Double { Self.InstantDuration }
    
    public var action: GameAction
    public var isComplete: Bool = false
    
    public init(
        action: GameAction
    ) {
        self.action = action
    }
        
    public mutating func run<State: BasicOperationCapableState>(
        id: EntityId,
        state: inout State,
        delta: Double
    ) -> GameEffect<State, GameAction> {
        guard !isComplete else { return .none }
        isComplete = true
        return .game(action)
    }
    
    public mutating func reset() {
        currentTime = 0
        isComplete = false
    }
}
