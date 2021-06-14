import Foundation

public protocol GameComponent: Codable, Equatable {
    var entity: EntityId { get }
}

public typealias RegisteredComponentId = String

public struct RegisteredComponentType<S: GameState>: Identifiable {
    public let id: RegisteredComponentId
    public let onEntityDestroyed: (EntityId, inout S) -> Void
    
    public init<C: GameComponent>(keyPath: WritableKeyPath<S, [EntityId: C]>) {
        id = String(describing: C.self)
        onEntityDestroyed = { entity, state in
            state[keyPath: keyPath][entity] = nil
        }
    }
}

extension RegisteredComponentType: Equatable {
    public static func == (lhs: RegisteredComponentType<S>, rhs: RegisteredComponentType<S>) -> Bool {
        lhs.id == rhs.id
    }
}

extension RegisteredComponentType: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
