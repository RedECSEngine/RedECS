import Geometry

public struct RemoveEntityOperation<GameAction: Equatable & Codable>: OperationPayload {
    public static var operationTypeId: OperationTypeId { "engine.removeEntity" }

    
    public var duration: Double = 0
    public var currentTime: Double = 0
    public var isComplete: Bool = false
    
    public var removeEntityId: EntityId?
    
    public init(removeEntityId: EntityId? = nil) {
        self.removeEntityId = removeEntityId
    }
    
    public mutating func run<S: GameState>(id: EntityId) -> GameEffect<S, GameAction> {
        isComplete = true
        return .system(.removeEntity(removeEntityId ?? id))
    }
    
    public mutating func reset() {
        assertionFailure("resetting a removal")
        isComplete = false
    }
}
