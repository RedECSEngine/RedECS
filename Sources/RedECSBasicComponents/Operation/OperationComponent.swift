import RedECS
import Geometry
import OrderedCollections

public protocol OperationCapableGameState: GameState {
    associatedtype GameAction: Equatable & Codable
    
    var operation: [EntityId: OperationComponent<GameAction>] { get set }
    var transform: [EntityId: TransformComponent] { get set }
    var sprite: [EntityId: SpriteComponent] { get set }
}

extension OperationCapableGameState {
    public var operationContext: OperationComponentContext<GameAction> {
        get {
            OperationComponentContext<GameAction>(
                entities: entities,
                operation: operation,
                transform: transform,
                sprite: sprite
            )
        }
        set {
            self.transform = newValue.transform
            self.operation = newValue.operation
            self.sprite = newValue.sprite
        }
    }
    
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
    public var operations: OrderedDictionary<String, OperationType<GameAction>>
    
    public init(entity: EntityId) {
        self = .init(entity: entity, operations: [:])
    }
    
    public init (
        entity: EntityId,
        operation: OperationType<GameAction>
    ) {
        self.init(entity: entity)
        self.newOperation(operation)
    }
    
    public init (
        entity: EntityId,
        operations: OrderedDictionary<String, OperationType<GameAction>> = [:]
    ) {
        self.entity =  entity
        self.operations = operations
    }
    
    public mutating func newOperation(_ type: OperationType<GameAction>) {
        let name = newEntityId()
        newOperation(name: name, type)
    }
    
    public mutating func newOperation(name: String, _ type: OperationType<GameAction>) {
        operations[name] = type
    }
    
    public mutating func removeOperation(name: String) {
        operations[name] = nil
    }
    
    public mutating func removeAllOperations() {
        operations.removeAll()
    }
}

