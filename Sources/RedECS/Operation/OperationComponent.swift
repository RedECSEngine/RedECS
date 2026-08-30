import Geometry
import OrderedCollections

public protocol OperationCapableGameState: BasicOperationCapableState {
    associatedtype GameAction: Equatable & Codable

    var operation: [EntityId: OperationComponent<GameAction>] { get set }
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

