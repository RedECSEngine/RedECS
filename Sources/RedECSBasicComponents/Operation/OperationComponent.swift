import RedECS
import Geometry

public protocol OperationCapable: GameState {
    associatedtype GameAction: Equatable & Codable
    
    var operation: [EntityId: OperationComponent<GameAction>] { get set }
    var transform: [EntityId: TransformComponent] { get set }
    var sprite: [EntityId: SpriteComponent] { get set }
}

extension OperationCapable {
    var basicOperationComponentState: BasicOperationComponentContext {
        get {
            BasicOperationComponentContext(
                entities: entities,
                transform: transform,
                sprite: sprite
            )
        }
        set {
            self.transform = newValue.transform
            self.sprite = newValue.sprite
        }
    }
}

public struct OperationComponent<GameAction: Equatable & Codable>: GameComponent {
    public var entity: EntityId
    public var type: OperationType<GameAction>?
    
    public init(entity: EntityId) {
        self = .init(entity: entity, type: nil)
    }
    
    public init (
        entity: EntityId,
        type: OperationType<GameAction>? = nil
    ) {
        self.entity =  entity
        self.type = type
    }
}

