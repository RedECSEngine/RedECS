import Foundation

public typealias RegisteredComponentId = String

public struct RegisteredComponentType<S: GameState>: Identifiable {
    public let id: RegisteredComponentId
    public let onEntityDestroyed: (EntityId, inout S) -> Void
    
    public init<C: GameComponent>(keyPath: WritableKeyPath<S, [EntityId: C]>) {
        id = String(describing: C.self)
        onEntityDestroyed = { entity, state in
            state[keyPath: keyPath][entity]?.prepareForDestruction()
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

public struct AnyComponent<S: GameState> {
    public let id: RegisteredComponentId
    public let onAdd: (EntityId, inout S) -> Void

    public init<C: GameComponent>(
        _ component: C,
        into keyPath: WritableKeyPath<S, [EntityId: C]>
    ) {
        id = String(describing: C.self)
        onAdd = { entity, state in
            state[keyPath: keyPath][entity] = component
        }
    }

    public init(
        id: RegisteredComponentId,
        onAdd: @escaping (EntityId, inout S) -> Void
    ) {
        self.id = id
        self.onAdd = onAdd
    }

    public func map<State>(_ stateTransform: WritableKeyPath<State, S>) -> AnyComponent<State> {
        return AnyComponent<State>(id: id, onAdd: { entity, state in
            onAdd(entity, &state[keyPath: stateTransform])
        })
    }
}

extension AnyComponent: Equatable {
    public static func == (lhs: AnyComponent<S>, rhs: AnyComponent<S>) -> Bool {
        lhs.id == rhs.id
    }
}

extension AnyComponent: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
