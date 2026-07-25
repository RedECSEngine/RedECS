import Geometry

public struct RemoveEntityOperation<GameAction: Equatable & Codable>: Operation {
    public typealias Action = GameAction
    
    public var duration: Double = 0
    public var currentTime: Double = 0
    public var isComplete: Bool = false
    
    public var removeEntityId: EntityId?
    
    public init(removeEntityId: EntityId? = nil) {
        self.removeEntityId = removeEntityId
    }
    
    public mutating func run(id: EntityId, state: inout BasicOperationComponentContext, delta: Double) -> GameEffect<BasicOperationComponentContext, Action> {
        isComplete = true
        return .system(.removeEntity(removeEntityId ?? id))
    }
    
    public mutating func reset() {
        assertionFailure("resetting a removal")
        isComplete = false
    }
}
