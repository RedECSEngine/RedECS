import Foundation

public indirect enum GameEffect<State: GameState, LogicAction: Equatable> {
    case system(SystemAction<State>)
    case game(LogicAction)
    case deferred(Promise<Self, Never>)
    case waitFor(PendingGameEffect<State, LogicAction>)
    case many([Self])
    case none
    
    func map<S: GameState, A>(
        stateTransform: WritableKeyPath<S, State>,
        actionTransform: @escaping (LogicAction) -> A
    ) -> GameEffect<S, A> {
        switch self {
        case .system(let action):
            return .system(action.map(stateTransform))
        case .game(let action):
            return .game(actionTransform(action))
        case .many(let effects):
            return .many(effects.map { $0.map(stateTransform: stateTransform, actionTransform: actionTransform) })
        case .deferred(let promise):
            return .deferred(promise.map({
                $0.map(stateTransform: stateTransform, actionTransform: actionTransform)
            }))
        case .waitFor(let pendingEffect):
            return .waitFor(pendingEffect.map(stateTransform: stateTransform, actionTransform: actionTransform))
        case .none:
            return .none
        }
    }
}

public enum SystemAction<State: GameState> {
    case addEntity(EntityId, Set<String>)
    case removeEntity(EntityId)
    case addComponent(EntityId, AnyComponent<State>)
    case removeComponent(EntityId, RegisteredComponentId)
    
    func map<S: GameState>(
        _ stateTransform: WritableKeyPath<S, State>
    ) -> SystemAction<S> {
        switch self {
        case .addEntity(let e, let tags):
            return .addEntity(e, tags)
        case .removeEntity(let e):
            return .removeEntity(e)
        case .addComponent(let eId, let registeredComponent):
            return .addComponent(eId, registeredComponent.map(stateTransform))
        case .removeComponent(let e, let registeredComponentId):
            return .removeComponent(e, registeredComponentId)
        }
    }
    
    public static func addComponent<C: GameComponent>(
        _ component: C,
        into keyPath: WritableKeyPath<State, [EntityId: C]>
    ) -> Self {
        .addComponent(component.entity, AnyComponent(component, into: keyPath))
    }
    
    public static func removeComponent<C: GameComponent>(
        ofType type: C.Type,
        forEntity entity: EntityId
    ) -> Self {
        .removeComponent(entity, String(describing: C.self))
    }
}
