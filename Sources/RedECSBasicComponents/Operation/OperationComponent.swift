import RedECS

public protocol OperationCapable {
    associatedtype GameAction: Equatable & Codable
    var operation: [EntityId: OperationComponent<GameAction>] { get set }
}

public struct OperationComponent<GameAction: Equatable & Codable>: GameComponent {
    public enum OperationType: Equatable & Codable {
        case wait(Double)
    }
    
    public var entity: EntityId
    public var type: OperationType
    public var delta: Double
    public var onComplete: GameAction
    
    public init (
        entity: EntityId,
        type: OperationType,
        delta: Double,
        onComplete: GameAction
    ) {
        self.entity =  entity
        self.type = type
        self.delta = delta
        self.onComplete = onComplete
    }
}

public extension GameEffect where State: OperationCapable, LogicAction == State.GameAction {
    static func operation(
        _ type: OperationComponent<LogicAction>.OperationType,
        then: LogicAction
    ) -> Self {
        let id = newEntityId(prefix: "operation")
        let operation = OperationComponent(entity: id, type: type, delta: 0, onComplete: then)
        return .many([
            .system(.addEntity(id, ["operation"])),
            .system(.addComponent(operation, into: \.operation))
        ])
    }
}
