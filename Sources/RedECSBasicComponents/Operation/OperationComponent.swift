import RedECS
import Geometry

public protocol OperationCapable: GameState {
    associatedtype GameAction: Equatable & Codable
    
    var operation: [EntityId: OperationComponent<GameAction>] { get set }
    var transform: [EntityId: TransformComponent] { get set }
}

extension OperationCapable {
    var basicOperationComponentState: BasicOperationComponentContext {
        get {
            BasicOperationComponentContext(entities: entities, transform: transform)
        }
        set {
            self.transform = newValue.transform
        }
    }
}

public struct OperationComponent<GameAction: Equatable & Codable>: GameComponent {
    public var entity: EntityId
    public var type: OperationType<GameAction>?
    
    public init (
        entity: EntityId,
        type: OperationType<GameAction>? = nil
    ) {
        self.entity =  entity
        self.type = type
    }
}

