
public struct CallOperation<GameAction: Equatable & Codable>: OperationPayload {
    public static var operationTypeId: OperationTypeId { "engine.call" }

    public var currentTime: Double = 0
    public var duration: Double { Self.InstantDuration }
    
    public var action: GameAction
    public var isComplete: Bool = false
    
    public init(
        action: GameAction
    ) {
        self.action = action
    }
        
    public mutating func run<S: GameState>(id: EntityId) -> GameEffect<S, GameAction> {
        guard !isComplete else { return .none }
        isComplete = true
        return .game(action)
    }
    
    public mutating func reset() {
        currentTime = 0
        isComplete = false
    }
}
