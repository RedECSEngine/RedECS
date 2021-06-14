import Foundation

public enum GameEffect<State: GameState, Action> {
    case systemAction(SystemAction<State>)
    case logicAction(Action)
    case many([Self])
    case none
    
    func map<S: GameState, A>(
        stateTransform: WritableKeyPath<S, State>,
        actionTransform: (Action) -> A
    ) -> GameEffect<S, A> {
        switch self {
        case .systemAction(let action):
            return .systemAction(action.map(stateTransform: stateTransform))
        case .logicAction(let action):
            return .logicAction(actionTransform(action))
        case .many(let effects):
            return .many(effects.map { $0.map(stateTransform: stateTransform, actionTransform: actionTransform) })
        case .none:
            return .none
        }
    }
}

public enum SystemAction<State: GameState> {
    case addEntity(EntityId)
    case removeEntity(EntityId)
    case addComponent(EntityId, RegisteredComponentId, (inout State) -> Void)
    case removeComponent(EntityId, (inout State) -> Void)
    
    func map<S: GameState>(
        stateTransform: WritableKeyPath<S, State>
    ) -> SystemAction<S> {
        switch self {
        case .addEntity(let e):
            return .addEntity(e)
        case .removeEntity(let e):
            return .removeEntity(e)
        case .addComponent(let eId, let cId,  let closure):
            return .addComponent(eId, cId) { state in
                closure(&state[keyPath: stateTransform])
            }
        case .removeComponent(let e, let closure):
            return .removeComponent(e) { state in
                closure(&state[keyPath: stateTransform])
            }
        }
    }
    
    public static func addComponent<C: GameComponent>(
        _ component: C,
        into keyPath: WritableKeyPath<State, [EntityId: C]>
    ) -> Self {
        .addComponent(component.entity, String(describing: C.self)) { state in
            assert(state.entities.contains(component.entity), "Inserting a component for unregistered entity")
            state[keyPath: keyPath][component.entity] = component
        }
    }
    
    public static func removeComponent<C: GameComponent>(
        ofType type: C.Type,
        from keyPath: WritableKeyPath<State, [EntityId: C]>,
        forEntity entity: EntityId
    ) -> Self {
        .removeComponent(entity) { state in
            state[keyPath: keyPath][entity] = nil
        }
    }
}
