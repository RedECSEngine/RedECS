public enum SystemAction<State: GameState> {
    case addEntity(EntityId, Set<String>)
    case removeEntity(EntityId)
    /// Reparents an entity in the entity tree; `nil` moves it back to the root.
    case setParent(EntityId, EntityId?)
    case addComponent(EntityId, AnyComponent<State>)
    case removeComponent(EntityId, RegisteredComponentId)
    /// Adds/removes a tag on an existing entity, keeping the reverse tag index
    /// in sync. Useful for moving a role marker (e.g. the controlled-player tag)
    /// from one entity to another at runtime.
    case addTag(EntityId, String)
    case removeTag(EntityId, String)
    case cancelPendingEffects

    public func map<S: GameState>(
        _ stateTransform: WritableKeyPath<S, State>
    ) -> SystemAction<S> {
        switch self {
        case .addEntity(let e, let tags):
            return .addEntity(e, tags)
        case .removeEntity(let e):
            return .removeEntity(e)
        case .setParent(let e, let p):
            return .setParent(e, p)
        case .addTag(let e, let tag):
            return .addTag(e, tag)
        case .removeTag(let e, let tag):
            return .removeTag(e, tag)
        case .addComponent(let eId, let registeredComponent):
            return .addComponent(eId, registeredComponent.map(stateTransform))
        case .removeComponent(let e, let registeredComponentId):
            return .removeComponent(e, registeredComponentId)
        case .cancelPendingEffects:
            return .cancelPendingEffects
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
