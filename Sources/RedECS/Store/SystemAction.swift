public enum SystemAction<State: GameState> {
    case addEntity(EntityId, Set<String>)
    case removeEntity(EntityId)
    case addComponent(EntityId, AnyComponent<State>)
    case removeComponent(EntityId, RegisteredComponentId)

    public func map<S: GameState>(
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
