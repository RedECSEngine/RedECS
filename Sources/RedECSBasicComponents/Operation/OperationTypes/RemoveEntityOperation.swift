import RedECS
import Geometry

public struct RemoveEntityOperation<GameAction: Equatable & Codable>: Operation {
    public typealias Action = GameAction
    
    public var duration: Double = 0
    public var currentTime: Double = 0
    public var isComplete: Bool = false
    
    public init() { }
    
    public mutating func run(id: EntityId, state: inout BasicOperationComponentContext, delta: Double) -> GameEffect<BasicOperationComponentContext, Action> {
        isComplete = true
        return .system(.removeEntity(id))
    }
    
    public mutating func reset() {
        assertionFailure("resetting a removal")
        isComplete = false
    }
}
